-- Create database schema
CREATE DATABASE microservices_db;

-- Connect to the database
\c microservices_db;

-- Create users table
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL UNIQUE,
    email VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes
CREATE INDEX idx_users_name ON users(name);
CREATE INDEX idx_users_created_at ON users(created_at);

-- Insert sample data
INSERT INTO users (name, email) VALUES
    ('Alice Johnson', 'alice@example.com'),
    ('Bob Smith', 'bob@example.com'),
    ('Charlie Brown', 'charlie@example.com'),
    ('Diana Prince', 'diana@example.com'),
    ('Ethan Hunt', 'ethan@example.com')
ON CONFLICT (name) DO NOTHING;

-- Create function for updated_at trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger for auto-updating updated_at
CREATE TRIGGER update_users_updated_at 
    BEFORE UPDATE ON users 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Create a view for user statistics
CREATE OR REPLACE VIEW user_stats AS
SELECT 
    COUNT(*) as total_users,
    COUNT(*) FILTER (WHERE created_at > CURRENT_DATE - INTERVAL '7 days') as users_last_week,
    COUNT(*) FILTER (WHERE created_at > CURRENT_DATE - INTERVAL '30 days') as users_last_month,
    MIN(created_at) as first_user_date,
    MAX(created_at) as latest_user_date
FROM users;

-- Grant permissions (for production use)
-- CREATE USER app_user WITH PASSWORD 'secure_password';
-- GRANT SELECT, INSERT, UPDATE, DELETE ON users TO app_user;
-- GRANT USAGE, SELECT ON SEQUENCE users_id_seq TO app_user;

-- Display initial data
SELECT 'Database initialized successfully!' as status;
SELECT * FROM user_stats;
SELECT 'Sample users:' as info;
SELECT id, name, email, created_at FROM users LIMIT 5;
