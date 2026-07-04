package marketplace

import (
	"sync"
	"time"
)

type cacheEntry struct {
	value     any
	expiresAt time.Time
}

// Cache 零依赖内存缓存 (sync.Map + TTL)
type Cache struct {
	m sync.Map
}

func NewCache() *Cache { return &Cache{} }

func (c *Cache) Get(key string) (any, bool) {
	v, ok := c.m.Load(key)
	if !ok {
		return nil, false
	}
	e := v.(*cacheEntry)
	if time.Now().After(e.expiresAt) {
		c.m.Delete(key)
		return nil, false
	}
	return e.value, true
}

func (c *Cache) Set(key string, value any, ttl time.Duration) {
	c.m.Store(key, &cacheEntry{value: value, expiresAt: time.Now().Add(ttl)})
}

func (c *Cache) Delete(key string) { c.m.Delete(key) }
