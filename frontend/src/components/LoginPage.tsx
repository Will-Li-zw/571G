// import React from 'react';
// import { useWeb3React } from '@web3-react/core';
// import { injected } from '../utils/connectors';
import { useEagerConnect, useInactiveListener } from '../utils/hooks';
import {  Box } from '@mui/material';
// // import { ReactComponent as MetaMaskIcon } from '../assets/metamask.svg'; // Assume you have a MetaMask SVG icon

// export function LoginPage() {
//   const { activate, active } = useWeb3React();

//   // Automatically try to connect to MetaMask
//   // useEagerConnect();

//   // Handle the connection manually when the user clicks the button
  
//   );
// }
import { useEffect } from 'react';
import { useWeb3React } from '@web3-react/core';
import { injected } from '../utils/connectors';
import { Container, Typography, Button } from '@mui/material';
import { useAppDispatch } from '../hooks';
import { setRemainingDraws, setCollection } from '../store/userSlice';
import { setCardImageMap } from '../store/cardImageMapSlice';
import { fetchUserData, fetchCardImageMap } from '../store/mockBackend';

export function LoginPage() {
  const { activate, active } = useWeb3React();
  const dispatch = useAppDispatch();

  useEffect(() => {
    console.log(`User active status: ${active}`); // For debugging
    if (active) {
      console.log('Fetching user data...'); // For debugging
      (async () => {
        try {
          const userData = await fetchUserData();
          dispatch(setRemainingDraws(userData.remainingDraws));
          dispatch(setCollection(userData.collection));

          const cardImageMapData = await fetchCardImageMap();
          dispatch(setCardImageMap(cardImageMapData));
        } catch (error) {
          console.error('Error fetching data:', error);
        }
      })();
    }
  }, [active, dispatch]);

  const handleLoginClick = async () => {
    try {
      await activate(injected);
      const userData = await fetchUserData();
      dispatch(setRemainingDraws(userData.remainingDraws));
      dispatch(setCollection(userData.collection));

      const cardImageMapData = await fetchCardImageMap();
      dispatch(setCardImageMap(cardImageMapData));

    } catch (error) {
      console.error('Error on logging in:', error);
    }
  };

  // useInactiveListener(!active);

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
    </Container>)
}
