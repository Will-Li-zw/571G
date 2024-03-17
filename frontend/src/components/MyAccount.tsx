// MyAccount.tsx

import React, { useState } from 'react';
import styled from 'styled-components';
import AccountInformation from './AccountInformation';
const MyAccountContainer = styled.div`
  // Style your container as needed
`;

const ContentArea = styled.main`
  width: 80%;
  display: flex;
  justify-content: space-between;
  padding: 20px;
`;

const BalanceSection = styled.section`
  flex: 1;
  margin-right: 20px;
`;

const QuickActionSection = styled.aside`
  width: 30%;
  display: flex;
  flex-direction: column;
`;

const Input = styled.input`
  padding: 8px;
  margin-top: 10px;
`;

const QuickActionButton = styled.button`
  padding: 8px;
  margin-top: 10px;
  cursor: pointer;
`;

export const MyAccount = () => {
  const [addBalance, setAddBalance] = useState('');
  const [withdrawBalance, setWithdrawBalance] = useState('');

  const handleAddBalance = () => {
    // Define what happens when the "Add Balance" button is clicked
    console.log(addBalance)
  };

  const handleWithdrawBalance = () => {
    // Define what happens when the "Withdraw Balance" button is clicked
    console.log(handleWithdrawBalance)

  };

  return (
    <MyAccountContainer>
      <ContentArea>
        <AccountInformation/>
        <QuickActionSection>
          <label>
            Quick Add Balance
            <Input type="text" value={addBalance} onChange={(e) => setAddBalance(e.target.value)} />
            <QuickActionButton onClick={handleAddBalance}>Submit</QuickActionButton>
          </label>
          <label>
            Quick Withdraw
            <Input type="text" value={withdrawBalance} onChange={(e) => setWithdrawBalance(e.target.value)} />
            <QuickActionButton onClick={handleWithdrawBalance}>Submit</QuickActionButton>
          </label>
        </QuickActionSection>
      </ContentArea>
    </MyAccountContainer>
  );
};
