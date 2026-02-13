# Connecting to PostgreSQL with pgAdmin

## Connection Details

Use these settings to connect pgAdmin to your Docker PostgreSQL database:

### Server Connection Settings

**General Tab:**
- **Name:** `Car Reselling DB` (or any name you prefer)

**Connection Tab:**
- **Host name/address:** `localhost`
- **Port:** `15432`
- **Maintenance database:** `postgres`
- **Username:** `postgres`
- **Password:** `postgres`
- **Save password:** ✓ (optional, for convenience)

### Step-by-Step Instructions

1. **Open pgAdmin**
   - Launch the pgAdmin application

2. **Add New Server**
   - Right-click on "Servers" in the left panel
   - Select "Register" → "Server..."

3. **Fill in General Tab**
   - **Name:** Enter a friendly name (e.g., "Car Reselling DB")

4. **Fill in Connection Tab**
   - **Host name/address:** `localhost`
   - **Port:** `15432`
   - **Maintenance database:** `postgres`
   - **Username:** `postgres`
   - **Password:** `postgres`
   - Check "Save password" if you want pgAdmin to remember it

5. **Advanced Tab (Optional)**
   - Leave default settings

6. **SSL Tab (Optional)**
   - **SSL mode:** `Prefer` or `Disable` (since we're using localhost)

7. **Click "Save"**

### Verify Connection

After saving, you should see:
- Your server listed under "Servers"
- Expand it to see:
  - **Databases** → `car_reselling_db`
  - **Login/Group Roles**
  - **Tablespaces**

### Access Your Database

1. Expand your server
2. Expand "Databases"
3. Expand "car_reselling_db"
4. Expand "Schemas" → "public"
5. Expand "Tables" to see:
   - `users`
   - `verification_codes`

### Troubleshooting

**Connection Refused:**
- Make sure Docker container is running: `docker-compose ps postgres`
- Verify port 15432 is not blocked by firewall

**Authentication Failed:**
- Double-check username: `postgres`
- Double-check password: `postgres`
- Verify these match your docker-compose.yml

**Can't See Database:**
- Make sure the database exists: `docker-compose exec postgres psql -U postgres -l`
- The database `car_reselling_db` should be listed

### Quick Connection Test

Test the connection from terminal:
```bash
psql -h localhost -p 15432 -U postgres -d car_reselling_db
```

If this works, pgAdmin should work too!

### Notes

- **Port 15432** is the host port (what you use from your machine)
- **Port 5432** is the container port (internal to Docker)
- The database is accessible from your host machine on port 15432
- All data persists in Docker volumes, so it won't be lost when containers restart

