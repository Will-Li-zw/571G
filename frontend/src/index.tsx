import React from 'react';
import ReactDOM from 'react-dom';
import { Provider } from 'react-redux';
import { Web3ReactProvider } from '@web3-react/core';
import { App } from './App';
import './index.css';
import { store } from './store/store'; // Make sure to import the store from where it's defined
import { getProvider } from './utils/provider';

ReactDOM.render(
  <React.StrictMode>
    <Web3ReactProvider getLibrary={getProvider}>
      <Provider store={store}> {/* Wrap with Provider and pass the store */}
        <App />
      </Provider>
    </Web3ReactProvider>
  </React.StrictMode>,
  document.getElementById('root')
);
