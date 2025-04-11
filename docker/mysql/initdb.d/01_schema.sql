CREATE TABLE users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  email VARCHAR(255) NOT NULL,
  name VARCHAR(255),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE INDEX index_users_on_email ON users(email);

-- Insert some test data
INSERT INTO users (email, name) VALUES 
  ('user1@example.com', 'User One'),
  ('user2@example.com', 'User Two'),
  ('user3@example.com', 'User Three');