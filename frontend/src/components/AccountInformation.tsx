// AccountInformation.tsx

import React, { useState, useEffect } from 'react';
import styled from 'styled-components';

const getBalance = async () => {
  // Mock balance fetching logic
  await new Promise((resolve) => setTimeout(resolve, 1000));
  return 100;
};

const getCollection = async () => {
  // Mock collection fetching logic
  await new Promise((resolve) => setTimeout(resolve, 1000));
  return [
    { id: 1, name: 'Card 1' },
    { id: 2, name: 'Card 2' },
    { id: 3, name: 'Card 3' },
    { id: 3, name: 'Card 3' },
    { id: 3, name: 'Card 3' },
    { id: 3, name: 'Card 3' },
    { id: 3, name: 'Card 3' },

  ];
};

const useAccountData = () => {
  const [balance, setBalance] = useState<number | null>(null);
  const [collection, setCollection] = useState<{ id: number; name: string }[] | null>(null);

  useEffect(() => {
    const fetchData = async () => {
      setBalance(await getBalance());
      setCollection(await getCollection());
    };
    fetchData();
  }, []);

  return { balance, collection };
};

const AccountInformationContainer = styled.div`
  // Add your styles for the container
  padding: 16px;
`;

const BalanceDisplay = styled.div`
  // Add your styles for the balance display
  margin-bottom: 16px; // Add some space below the balance
`;

const CollectionDisplay = styled.div`
  display: flex;
  flex-direction:column;
  flex-wrap: wrap;
  gap: 10px; // Provides space between cards horizontally and vertically
  justify-content: flex-start; // Aligns cards to the start of the container
  align-items: flex-start; // Aligns cards to the top of the container
`;

const CardRow = styled.div`
display: flex;
flex-wrap:wrap;
`;

const Card = styled.div`
  border: 1px solid #ddd;
  box-shadow: 0px 2px 4px rgba(0,0,0,0.1);
  padding: 16px;
  border-radius: 8px;
  height: 150px;
  display: flex;
  align-items: center;
  justify-content: center;
  background-color: white;
  width: 25%;
`;
const AccountInformation = () => {
  const { balance, collection } = useAccountData();

  return (
    <AccountInformationContainer>
      <BalanceDisplay>
        <h2>Balance</h2>
        <p>{balance !== null ? `${balance} ETH` : 'Loading...'} </p>
      </BalanceDisplay>
      <CollectionDisplay>
        <h2>My Collection</h2>
        <CardRow>
        {collection !== null ? (
          collection.map((card) => (
            <Card key={card.id}>
              {card.name}
            </Card>
          ))
        ) : (
          'Loading...'
        )}    
        </CardRow>
        
      </CollectionDisplay>
    </AccountInformationContainer>
  );
};

export default AccountInformation;
