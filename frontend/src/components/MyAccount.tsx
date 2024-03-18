import React from 'react';
import AccountInformation from './AccountInformation';
import { Container, Box } from '@mui/material';

export const MyAccount = () => {
  return (
    <Container maxWidth="lg">
      <Box sx={{ my: 2, display: 'flex', flexDirection: 'column', alignItems: 'flex-start' }}>
        <AccountInformation />
      </Box>
    </Container>
  );
};
