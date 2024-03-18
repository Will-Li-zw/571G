import React, { useState } from 'react';
import { Grid, Card, CardContent, Button, Typography, CardMedia } from '@mui/material';

// Function to get image URL based on card ID
const imageUrls: { [key: number]: string } = {
  11:'https://i.postimg.cc/3RXLFz5z/163111-1710059471b82d.jpg',
  22:'https://i.postimg.cc/fR41mGPj/194048-1710070848523b.jpg',
  33: 'https://i.postimg.cc/rFTPp1RQ/TEC3-L07-N0965-lead-720x1280.png',
  44: 'https://via.placeholder.com/100/FFFACD',
  55: 'https://via.placeholder.com/100/8A2BE2',
  66: 'https://via.placeholder.com/100/DEB887',
  // ... Add more mappings as needed
};

const getImageUrlForCardId = (cardId: number): string => {
  return imageUrls[cardId] || 'https://via.placeholder.com/100/FFFFFF'; // Fallback image
};


// Mockup data for the store content
const mockupStoreContent = [
  {
    id: 1,
    requiredCardIds: [11, 22, 33],
    content: 'Exclusive Set A',
  },
  {
    id: 2,
    requiredCardIds: [44, 55, 66],
    content: 'Exclusive Set B',
  },
  // Add more awards as needed
];

// Function to simulate redeeming an award
const redeemAward = (awardId:number) => {
  console.log(`Redeeming award with ID: ${awardId}`);
  // Placeholder for actual redeem logic or API call
};

export const Store = () => {
  const [storeContent] = useState(mockupStoreContent);

  return (
    <Grid container spacing={2} sx={{ padding: 2 }}>
      {storeContent.map((award) => (
        <Grid item key={award.id} xs={12} sm={6} lg={4}>
          <Card raised sx={{ maxWidth: 345, mb: 2 }}>
            <CardContent>
              <Typography gutterBottom variant="h5" component="div">
                {award.content}
              </Typography>
              {award.requiredCardIds.map((cardId) => (
                <Card key={cardId} sx={{ mb: 1, display: 'inline-flex', width: 100, height: 140 }}>
                  <CardMedia
                    component="img"
                    height="140"
                    image={getImageUrlForCardId(cardId)}
                    alt={`Card ${cardId}`}
                  />
                </Card>
              ))}
              <Button variant="outlined" color="primary" onClick={() => redeemAward(award.id)} sx={{ mt: 1 }}>
                Redeem
              </Button>
            </CardContent>
          </Card>
        </Grid>
      ))}
    </Grid>
  );
};
