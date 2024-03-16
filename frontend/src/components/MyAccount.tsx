// MyAccount.tsx

import React from 'react';
import styled from 'styled-components';

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
  return (
    <MyAccountContainer>
      {/* Content for My Account will go here */}
      <ContentArea>
        <BalanceSection>
          {/* Balance and collection content here */}
        </BalanceSection>
        <QuickActionSection>
          {/* Quick add and withdraw actions here */}
          <label>
            Quick Add Balance
            <Input type="text" />
            <QuickActionButton>✔️</QuickActionButton>
          </label>
          <label>
            Quick Withdraw
            <Input type="text" />
            <QuickActionButton>✔️</QuickActionButton>
          </label>
        </QuickActionSection>
      </ContentArea>
    </MyAccountContainer>
  );
};

