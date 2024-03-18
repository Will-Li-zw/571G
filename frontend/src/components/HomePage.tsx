import React from 'react';
import { MyAccount } from './MyAccount'; // Your path may vary
import { DrawCard } from './DrawCard'; // Your path may vary
import { Store } from './Store'; // Your path may vary
import { Routes, Route, NavLink, Outlet, useNavigate } from 'react-router-dom';
import { AppBar, Toolbar, Typography, Button, Box, Grid, Container } from '@mui/material';
import { useWeb3React } from '@web3-react/core';

export const HomePage = () => {
  const { deactivate } = useWeb3React();
  const navigate = useNavigate();

  const handleSignOut = () => {
    deactivate();
    navigate('/');
  };

  return (
    <Container maxWidth="lg">
      <AppBar position="static">
        <Toolbar>
          <Typography variant="h6" sx={{ flexGrow: 1 }}>
            Logo
          </Typography>
          <Button color="inherit" onClick={handleSignOut}>Sign out</Button>
        </Toolbar>
      </AppBar>
      <Grid container spacing={2} my={4}>
        <Grid item xs={12}>
          <nav style={{ textAlign: 'left' }}> {/* Align the navigation links to the left */}
            <Button component={NavLink} to="/home/myaccount" sx={{ marginRight: 2, textAlign: 'left' }}>
              My Account
            </Button>
            <Button component={NavLink} to="/home/drawcard" sx={{ marginRight: 2 }}>
              Draw Card
            </Button>
            <Button component={NavLink} to="/home/store">
              Store
            </Button>
          </nav>
        </Grid>
        <Grid item xs={12}>
          <Outlet /> {/* This will render the selected route component */}
        </Grid>
      </Grid>
      <Routes>
        <Route path="myaccount" element={<MyAccount />} />
        <Route path="drawcard" element={<DrawCard />} />
        <Route path="store" element={<Store />} />
        <Route index element={<MyAccount />} />
      </Routes>
    </Container>
  );
};

export default HomePage;
