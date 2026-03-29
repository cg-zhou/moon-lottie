import React from 'react'
import ReactDOM from 'react-dom/client'
import 'antd/dist/reset.css'
import 'iconify-icon'
import App from './App'
import './index.css'
import icons from './icons.json'
import { addIcon } from 'iconify-icon'

// Load icons locally
Object.values(icons).forEach(set => {
  Object.entries(set.icons).forEach(([name, data]) => {
    addIcon(`${set.prefix}:${name}`, {
      body: data.body,
      width: set.width,
      height: set.height
    });
  });
});

ReactDOM.createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>,
)
