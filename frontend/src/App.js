import React, { useState, useEffect } from 'react';
import axios from 'axios';
import './App.css';

function App() {
  const [users, setUsers] = useState([]);
  const [newUser, setNewUser] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  // API base URL
  const API_URL = process.env.REACT_APP_API_URL || '/api';

  // Fetch users
  const fetchUsers = async () => {
    try {
      setLoading(true);
      const response = await axios.get(`${API_URL}/users`);
      setUsers(response.data);
      setError('');
    } catch (err) {
      setError('Erreur lors du chargement des utilisateurs');
      console.error('Fetch error:', err);
    } finally {
      setLoading(false);
    }
  };

  // Add user
  const addUser = async (e) => {
    e.preventDefault();
    if (!newUser.trim()) return;
    
    try {
      setLoading(true);
      await axios.post(`${API_URL}/users`, { name: newUser });
      setNewUser('');
      fetchUsers(); // Refresh list
    } catch (err) {
      setError('Erreur lors de l\'ajout de l\'utilisateur');
      console.error('Add error:', err);
    } finally {
      setLoading(false);
    }
  };

  // Delete user
  const deleteUser = async (id) => {
    try {
      setLoading(true);
      await axios.delete(`${API_URL}/users/${id}`);
      fetchUsers(); // Refresh list
    } catch (err) {
      setError('Erreur lors de la suppression');
      console.error('Delete error:', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchUsers();
  }, []);

  return (
    <div className="App">
      <header className="header">
        <h1>🚀 Microservices Demo</h1>
        <p>Frontend React + Backend Node.js + PostgreSQL</p>
      </header>

      <main className="main">
        <div className="container">
          
          {/* Add User Form */}
          <div className="card">
            <h2>➕ Ajouter un utilisateur</h2>
            <form onSubmit={addUser} className="form">
              <input
                type="text"
                value={newUser}
                onChange={(e) => setNewUser(e.target.value)}
                placeholder="Nom de l'utilisateur"
                className="input"
                disabled={loading}
              />
              <button type="submit" className="button primary" disabled={loading}>
                {loading ? '⏳ Ajout...' : '✅ Ajouter'}
              </button>
            </form>
          </div>

          {/* Error Display */}
          {error && (
            <div className="alert error">
              ❌ {error}
              <button onClick={() => setError('')} className="close">✖</button>
            </div>
          )}

          {/* Users List */}
          <div className="card">
            <h2>👥 Utilisateurs ({users.length})</h2>
            
            {loading && <div className="loading">⏳ Chargement...</div>}
            
            {users.length === 0 && !loading && (
              <div className="empty">
                📝 Aucun utilisateur. Ajoutez-en un !
              </div>
            )}

            <div className="users-grid">
              {users.map((user) => (
                <div key={user.id} className="user-card">
                  <div className="user-info">
                    <span className="user-name">{user.name}</span>
                    <span className="user-id">ID: {user.id}</span>
                    <span className="user-date">
                      📅 {new Date(user.created_at).toLocaleDateString()}
                    </span>
                  </div>
                  <button
                    onClick={() => deleteUser(user.id)}
                    className="button danger"
                    disabled={loading}
                  >
                    🗑️
                  </button>
                </div>
              ))}
            </div>
          </div>

          {/* Stats */}
          <div className="stats">
            <div className="stat-item">
              <span className="stat-number">{users.length}</span>
              <span className="stat-label">Utilisateurs</span>
            </div>
            <div className="stat-item">
              <span className="stat-number">🟢</span>
              <span className="stat-label">Status</span>
            </div>
          </div>
        </div>
      </main>

      <footer className="footer">
        <p>🐳 Containerized with Docker | ☸️ Orchestrated with Kubernetes</p>
      </footer>
    </div>
  );
}

export default App;
