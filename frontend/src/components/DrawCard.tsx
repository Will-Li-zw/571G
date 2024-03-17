// DrawCard.tsx

import React, { useState } from 'react';
import styled from 'styled-components';

const DrawCardContainer = styled.div`
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 20px;
`;

const SpinningWheel = styled.div`
  width: 200px;
  height: 200px;
  border: 3px solid #333;
  border-radius: 50%;
  display: flex;
  justify-content: center;
  align-items: center;
  cursor: pointer;
  &:active {
    transform: rotate(360deg);
    transition: transform 0.8s ease-out;
  }
`;

const ResultDisplay = styled.div`
  margin-top: 20px;
`;

// Mockup function to simulate drawing a card number
const getDrawNumber = () => {
  // Simulate generating a random card ID between 1 and 100
  return Math.floor(Math.random() * 100) + 1;
};

export const DrawCard = () => {
  const [cardId, setCardId] = useState(0);
  const [isSpinning, setIsSpinning] = useState(false);

  const handleSpinClick = () => {
    setIsSpinning(true);
    setTimeout(() => {
      const drawnCardId = getDrawNumber();
      setCardId(drawnCardId);
      setIsSpinning(false);
    }, 800); // Assuming the spinning animation takes 0.8 seconds
  };

  return (
    <DrawCardContainer>
      <SpinningWheel onClick={handleSpinClick}>
        {isSpinning ? 'Spinning...' : 'Click to Spin'}
      </SpinningWheel>
      <ResultDisplay>
        {cardId !== null && !isSpinning && `You drew card number: ${cardId}`}
      </ResultDisplay>
    </DrawCardContainer>
  );
};
