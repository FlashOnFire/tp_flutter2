# Timestamp Synchronization Implementation

## Summary

All database tables and API endpoints have been updated to support `created_at` timestamps for synchronization purposes.

## Database Schema Changes

### 1. Auteur Table
```sql
CREATE TABLE IF NOT EXISTS auteur (
  id INT AUTO_INCREMENT PRIMARY KEY,
  nom VARCHAR(255) NOT NULL,
  prenom VARCHAR(255) NOT NULL,
  mail VARCHAR(255),
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
```

### 2. Categorie Table
```sql
CREATE TABLE IF NOT EXISTS categorie (
  id INT AUTO_INCREMENT PRIMARY KEY,
  libelle VARCHAR(255) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
```

### 3. Livre Table
```sql
CREATE TABLE IF NOT EXISTS livre (
  id INT AUTO_INCREMENT PRIMARY KEY,
  libelle VARCHAR(255) NOT NULL,
  description TEXT,
  auteur_id INT NOT NULL,
  categorie_id INT NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (auteur_id) REFERENCES auteur(id) ON DELETE CASCADE,
  FOREIGN KEY (categorie_id) REFERENCES categorie(id) ON DELETE CASCADE
);
```

## API Changes

### Controller Updates

All create methods now:
1. Accept an optional `created_at` parameter in the request body
2. Use the provided timestamp if present, otherwise generate current timestamp
3. Return the `created_at` value in the response

#### Example: Livre Controller
```javascript
exports.create = (req, res) => {
  const { libelle, description, auteur_id, categorie_id, created_at } = req.body;
  const timestamp = created_at || new Date().toISOString().slice(0, 19).replace('T', ' ');
  
  db.query(
    "INSERT INTO livre (libelle, description, auteur_id, categorie_id, created_at) VALUES (?, ?, ?, ?, ?)",
    [libelle, description, auteur_id, categorie_id, timestamp],
    (err, result) => {
      if (err) return res.status(500).json(err);
      res.status(201).json({ id: result.insertId, created_at: timestamp });
    }
  );
};
```

### GET Endpoints

All GET endpoints now return the `created_at` field for synchronization:

- **GET /api/auteurs** - Returns `created_at` for each author
- **GET /api/categories** - Returns `created_at` for each category  
- **GET /api/livres** - Returns `created_at` for each book (included in JOIN query)

## Usage Examples

### Creating with Custom Timestamp

#### Create Auteur
```bash
curl -X POST http://localhost:3000/api/auteurs \
  -H "Content-Type: application/json" \
  -d '{
    "nom": "Tolkien",
    "prenom": "J.R.R.",
    "mail": "tolkien@example.com",
    "created_at": "2024-01-15 10:30:00"
  }'
```

Response:
```json
{
  "id": 5,
  "created_at": "2024-01-15 10:30:00"
}
```

#### Create Categorie
```bash
curl -X POST http://localhost:3000/api/categories \
  -H "Content-Type: application/json" \
  -d '{
    "libelle": "Fantasy",
    "created_at": "2024-01-15 10:35:00"
  }'
```

Response:
```json
{
  "id": 6,
  "created_at": "2024-01-15 10:35:00"
}
```

#### Create Livre (with JWT)
```bash
curl -X POST http://localhost:3000/api/livres \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -d '{
    "libelle": "Le Seigneur des Anneaux",
    "description": "Trilogie épique",
    "auteur_id": 5,
    "categorie_id": 6,
    "created_at": "2024-01-15 11:00:00"
  }'
```

Response:
```json
{
  "id": 6,
  "created_at": "2024-01-15 11:00:00"
}
```

### Creating without Custom Timestamp

If `created_at` is not provided, the server automatically generates the current timestamp:

```bash
curl -X POST http://localhost:3000/api/auteurs \
  -H "Content-Type: application/json" \
  -d '{
    "nom": "Rowling",
    "prenom": "J.K.",
    "mail": "rowling@example.com"
  }'
```

Response (with auto-generated timestamp):
```json
{
  "id": 6,
  "created_at": "2026-01-23 15:30:45"
}
```

## Synchronization Use Cases

### 1. Offline-First Mobile App
When a mobile app creates data offline and syncs later:
```javascript
// Mobile app stores creation time when offline
const localTimestamp = "2026-01-23 10:00:00";

// Later, when online, syncs with server using original timestamp
await api.createAuteur({
  nom: "Hemingway",
  prenom: "Ernest",
  created_at: localTimestamp  // Preserves original creation time
});
```

### 2. Data Import/Migration
When importing existing data from another system:
```javascript
// Preserve original creation timestamps during migration
existingRecords.forEach(record => {
  api.createCategorie({
    libelle: record.name,
    created_at: record.originalCreationDate  // Keep original timestamp
  });
});
```

### 3. Conflict Resolution
Use timestamps to determine which version is newer:
```javascript
// Get all records created after last sync
const lastSync = "2026-01-23 12:00:00";
const newRecords = await api.getLivres()
  .then(livres => livres.filter(l => l.created_at > lastSync));
```

## Swagger Documentation

All POST endpoints now document the `created_at` parameter:

```yaml
created_at:
  type: string
  format: date-time
  description: Timestamp de création (optionnel, généré automatiquement si absent)
```

## Database Restart Required

To apply these changes:

```bash
cd api-server
docker compose down -v  # Remove volumes to recreate database
docker compose up --build -d
```

## Testing Timestamps

### Test Auto-Generated Timestamp
```bash
# Create without timestamp
curl -X POST http://localhost:3000/api/categories \
  -H "Content-Type: application/json" \
  -d '{"libelle": "Test Category"}'

# Verify created_at is auto-generated in response
```

### Test Custom Timestamp
```bash
# Create with custom timestamp
curl -X POST http://localhost:3000/api/categories \
  -H "Content-Type: application/json" \
  -d '{"libelle": "Old Category", "created_at": "2020-01-01 00:00:00"}'

# Verify returned timestamp matches input
```

### Test GET with Timestamps
```bash
# Get all categories with timestamps
curl http://localhost:3000/api/categories | jq .

# Response includes created_at for each item
# [
#   {
#     "id": 1,
#     "libelle": "Roman",
#     "created_at": "2026-01-23T14:30:00.000Z"
#   },
#   ...
# ]
```

## Benefits

1. **Synchronization**: Mobile apps can sync data while preserving original creation times
2. **Audit Trail**: Track when each record was actually created
3. **Conflict Resolution**: Use timestamps to resolve sync conflicts
4. **Data Import**: Preserve original timestamps when migrating data
5. **Offline Support**: Allow offline creation with later sync using original timestamp

## Backward Compatibility

- `created_at` is **optional** in POST requests
- If not provided, server auto-generates current timestamp
- Existing clients continue to work without modification
- New clients can leverage timestamp synchronization

---

**Status**: Implementation complete, ready for deployment after database restart.
