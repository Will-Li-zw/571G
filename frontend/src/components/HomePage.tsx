// HomePage.tsx

import React from 'react';
import { Routes, Route, NavLink, Outlet, useNavigate } from 'react-router-dom';
import { MyAccount } from './MyAccount'; // Your path may vary
import { DrawCard } from './DrawCard'; // Your path may vary
import { Store } from './Store'; // Your path may vary
import styled from 'styled-components';
import { useWeb3React } from '@web3-react/core';
import { WalletStatus } from './WalletStatus';

// Define styled components with details as per the image
const PageContainer = styled.div`
  display: flex;
  flex-direction: column;
  align-items: center;
  width: 100%;
`;

const Header = styled.header`
  width: 80%;
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 20px;
`;

const Logo = styled.div`
  font-size: 24px; // Example size, adjust as needed
  font-weight: bold;
`;

const UserID = styled.div`
  font-size: 16px; // Example size, adjust as needed
`;

const SignOutButton = styled.button`
  padding: 8px 16px;
  border: 1px solid #000;
  background-color: transparent;
  cursor: pointer;
`;

const NavigationBar = styled.nav`
  width: 80%;
  margin: 20px 0;
  display: flex;
  justify-content: center;
`;

const NavButton = styled(NavLink)`
  padding: 10px 20px;
  text-decoration: none;
  color: black;
  border-bottom: 2px solid transparent;

  &.active {
    border-bottom: 2px solid black;
  }
`;




// Define other components as needed

export const HomePage = () => {
  const { deactivate } = useWeb3React();
  const navigate = useNavigate();

  const handleSignOut = () => {
    deactivate(); // Disconnect the wallet
    navigate('/'); // Redirect to the login page
  };

  return (
    <PageContainer>
      <Header>
        <Logo>Logo</Logo>
        <WalletStatus/>
        <SignOutButton onClick={handleSignOut}>Sign out</SignOutButton>
      </Header>
      <NavigationBar>
        <NavButton to="/home/myaccount">
          My Account
        </NavButton>
        <NavButton to="/home/drawcard" >
          Draw Card
        </NavButton>
        <NavButton to="/home/store">
          Store
        </NavButton>
      </NavigationBar>
      <Outlet />
      <Routes>
        <Route path="myaccount" element={<MyAccount />} />
        <Route path="drawcard" element={<DrawCard />} />
        <Route path="store" element={<Store />} />
        <Route index element={<MyAccount />} />
      </Routes>
    </PageContainer>
  );
};
