import React from 'react';
import { useWeb3React } from '@web3-react/core';
import { injected } from '../utils/connectors';
import { useEagerConnect, useInactiveListener } from '../utils/hooks';
import { Container, Typography, Button, Box } from '@mui/material';
// import { ReactComponent as MetaMaskIcon } from '../assets/metamask.svg'; // Assume you have a MetaMask SVG icon

export function LoginPage() {
  const { activate, active } = useWeb3React();

  // Automatically try to connect to MetaMask
  // useEagerConnect();

  // Handle the connection manually when the user clicks the button
  const handleLoginClick = async () => {
    try {
      await activate(injected);
    } catch (error) {
      console.error('Error on logging in:', error);
    }
  };

  useInactiveListener(!active);

  return (
    <Container maxWidth="xs" sx={{ height: '100vh', display: 'flex', flexDirection: 'column', justifyContent: 'center', alignItems: 'center' }}>
      <Box sx={{ mb: 4 }}>
        {/* <MetaMaskIcon width={64} height={64} /> */}
      </Box>
      <Typography variant="h4" component="h1" gutterBottom>
        Pyramid
      </Typography>
      <Button
        variant="contained"
        color="primary"
        onClick={handleLoginClick}
        disabled={active}
        // startIcon={<MetaMaskIcon />}
        sx={{ mt: 2, width: '100%', borderRadius: 20, p: '10px' }}
      >
        {active ? 'Connected' : 'Login with MetaMask'}
      </Button>
    </Container>
  );
}
