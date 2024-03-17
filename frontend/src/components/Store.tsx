// Store.tsx

import React, { useState } from 'react';
import styled from 'styled-components';

const StoreContainer = styled.div`
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 20px;
`;

const AwardContainer = styled.div`
  border: 1px solid #ccc;
  padding: 20px;
  margin-bottom: 20px;
`;

const Card = styled.div`
  width: 100px;
  height: 140px;
  border: 1px solid #000;
  display: inline-block;
  margin: 5px;
`;

const SubmitButton = styled.button`
  padding: 10px 15px;
  margin-top: 10px;
  cursor: pointer;
`;

const mockupStoreContent = [
  {
    id: 1,
    requiredCardIds: [11, 22, 33],
    content: 'Award1 Content',
  },
  {
    id: 2,
    requiredCardIds: [44, 55, 66],
    content: 'Award2 Content',
  },
  // ...add more awards as needed
];

// A mock function to simulate redeeming an award
const redeemAward = (awardId:any) => {
  console.log('Redeeming award with ID:', awardId);
  // Here you would put the actual redeem logic or API call
};

export const Store = () => {
  // You could fetch the store content from an API in a real application
  const [storeContent, setStoreContent] = useState(mockupStoreContent);

  return (
    <StoreContainer>
      {storeContent.map((award) => (
        <AwardContainer key={award.id}>
          <div>{award.content}</div>
          <div>
            {award.requiredCardIds.map((cardId) => (
              <Card key={cardId}>Card {cardId}</Card>
            ))}
          </div>
          <SubmitButton onClick={() => redeemAward(award.id)}>
            Redeem
          </SubmitButton>
        </AwardContainer>
      ))}
    </StoreContainer>
  );
};
