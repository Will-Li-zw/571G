import React from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { HomePage } from './components/HomePage';
import { LoginPage } from './components/LoginPage';
import { useWeb3React } from '@web3-react/core';
import { useEffect } from 'react';
import { useAppDispatch } from './hooks'; 
import { setCardImageMap } from './store/cardImageMapSlice';
// import { fetchUserData, fetchCardImageMap } from './store/mockBackend';
import { setAddress, setRemainingDraws, setCollection } from './store/userSlice';
import { getBalance, getUserCollection,getAllCollections,getAllRewards,getURLMap } from './store/interact';
import { setPoolProbMap } from './store/poolProbMapSlice';
import { setRewardMap } from './store/rewardMapSlice';
export function App(): React.ReactElement {
  const { active, account } = useWeb3React();
  const dispatch = useAppDispatch();
  
  // console.log(active)
  useEffect(() => {
    console.log(`User active status: ${active}`); // For debugging
    if (active) {
      console.log('Fetching user data...'); // For debugging
      (async () => {
        try {
          // console.log(account)
          dispatch(setAddress(account?account:""))

          // const userData = await fetchUserData();
          const balance = await getBalance();
          const collections = await getUserCollection()
          // console.log(balance,"HomePageBalance")
          dispatch(setRemainingDraws(balance));
          dispatch(setCollection(collections));
          const poolData = await getAllCollections();
          dispatch(setPoolProbMap(poolData));
      
          const rewardData = await getAllRewards();
          dispatch(setRewardMap(rewardData));
          const cardImageMapData = await getURLMap();
          console.log("cardImageMapDatac",cardImageMapData)
          dispatch(setCardImageMap(cardImageMapData));
        } catch (error) {
          console.error('Error fetching data:', error);
        }
      })();
    }
  }, [active, dispatch, account]);
  return (
    <Router>
      <Routes>
        <Route path="/" element={!active ? <LoginPage /> : <Navigate to="/home" />} />
        <Route path="/home/*" element={<HomePage />} />
      </Routes>
    </Router>
  );
}
