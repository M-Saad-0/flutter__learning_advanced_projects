package main

import (
	"encoding/json"
	"log"
	"net/http"
	"sync"

	"github.com/gin-gonic/gin"
	"github.com/gorilla/websocket"
)

var upgrader = websocket.Upgrader{
	ReadBufferSize:  1024,
	WriteBufferSize: 1024,
	CheckOrigin: func(r *http.Request) bool {
		return true // Allow all origins during local dev
	},
}

type Client struct {
	conn *websocket.Conn
	mu   sync.Mutex
}

type Hub struct {
	clients map[*Client]bool
	mu      sync.RWMutex
}

func NewHub() *Hub {
	return &Hub{
		clients: make(map[*Client]bool),
	}
}

func (h *Hub) RegisterClient(client *Client) {
	h.mu.Lock()
	defer h.mu.Unlock()
	h.clients[client] = true
	log.Printf("Client %s registered. Total clients: %d", client.conn.RemoteAddr(), len(h.clients))
}

func (h *Hub) UnregisterClient(client *Client) {
	h.mu.Lock()
	defer h.mu.Unlock()
	if _, ok := h.clients[client]; ok {
		delete(h.clients, client)
		log.Printf("Client %s unregistered. Total clients: %d", client.conn.RemoteAddr(), len(h.clients))
	}
}

func (h *Hub) BroadcastMessage(sender *Client, message []byte) {
	h.mu.RLock()
	defer h.mu.RUnlock()

	for client := range h.clients {
		if client == sender {
			continue
		}

		client.mu.Lock()
		err := client.conn.WriteMessage(websocket.TextMessage, message)
		client.mu.Unlock()

		if err != nil {
			log.Printf("Error broadcasting to client %s: %v", client.conn.RemoteAddr(), err)
			h.UnregisterClient(client)
			client.conn.Close()
		}
	}
}

var globalHub = NewHub()

func websocketHandler(c *gin.Context) {
	conn, err := upgrader.Upgrade(c.Writer, c.Request, nil)
	if err != nil {
		log.Printf("WebSocket upgrade error: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to upgrade WebSocket"})
		return
	}

	client := &Client{conn: conn}
	globalHub.RegisterClient(client)

	defer func() {
		globalHub.UnregisterClient(client)
		conn.Close()
	}()

	log.Printf("WebSocket client connected from %s!", client.conn.RemoteAddr())

	for {
		messageType, p, err := client.conn.ReadMessage()
		if err != nil {
			if websocket.IsCloseError(err, websocket.CloseGoingAway, websocket.CloseAbnormalClosure) {
				log.Printf("Client %s disconnected: %v", client.conn.RemoteAddr(), err)
			} else {
				log.Printf("Read error from %s: %v", client.conn.RemoteAddr(), err)
			}
			break
		}

		log.Printf("Message received from %s: %s (Type: %d)", client.conn.RemoteAddr(), p, messageType)

		// ✅ Wrap the message in JSON as expected by Flutter
		wrapped := map[string]interface{}{
			"data":   string(p),
			"isUser": false,
		}
		msgBytes, err := json.Marshal(wrapped)
		if err != nil {
			log.Printf("JSON marshal error: %v", err)
			continue
		}

		globalHub.BroadcastMessage(client, msgBytes)
	}

	log.Printf("WebSocket handler for %s ended.", client.conn.RemoteAddr())
}

func main() {
	router := gin.Default()

	router.GET("/", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"message": "The server is running!",
		})
	})

	router.GET("/ws", websocketHandler)

	if err := router.Run(":8080"); err != nil {
		panic("Failed to start server: " + err.Error())
	}
}
