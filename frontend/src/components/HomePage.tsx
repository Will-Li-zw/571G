import React from 'react';
import { MyAccount } from './MyAccount'; // Your path may vary
import { DrawCard } from './DrawCard'; // Your path may vary
import { Store } from './Store'; // Your path may vary
import { useEffect, useState } from 'react';
import { Routes, Route, NavLink, Outlet, useNavigate } from 'react-router-dom';
import { AppBar, Toolbar, Typography, Button, Box, Grid, Container } from '@mui/material';
import { useWeb3React } from '@web3-react/core';
import { WalletStatus } from './WalletStatus';
import AdminPage from './AdminPage';
import { checkAdmin } from '../store/interact';

export const HomePage = () => {
  const { deactivate } = useWeb3React();
  const navigate = useNavigate();
  const [isAdmin, setIsAdmin] = useState(false);

  useEffect(() => {
    // Simulate a backend request to check if the current user is an admin
    const checkAdminStatus = async () => {
      // Here you would typically fetch the user's role from the backend
      // For this example, let's assume a mock function that checks the address
      const isAdmine = await checkAdmin()
      // const adminAddress = ""; // Example admin address
      // const userAddress = ""; // Placeholder for actual user address logic
      setIsAdmin(isAdmine);
    };
    checkAdminStatus();
  }, []);
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
          <WalletStatus/>
          <Button color="inherit" onClick={handleSignOut}>Sign out</Button>
        </Toolbar>
      </AppBar>
      <Grid container spacing={2} my={4}>
        <Grid item xs={12}>
          <nav style={{ textAlign: 'left' }}> {/* Align the navigation links to the left */}
            {isAdmin && (
              <Button component={NavLink} to="/home/admin" sx={{ marginRight: 2 }}>
                Admin Page
              </Button>
            )}
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
        <Route path="admin" element={<AdminPage />} />
        <Route index element={<MyAccount />} />
      </Routes>
    </Container>
  );
};

export default HomePage;
