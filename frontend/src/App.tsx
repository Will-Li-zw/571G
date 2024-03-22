// import { ReactElement } from 'react';
// import styled from 'styled-components';
// import { BrowserRouter as Router, Routes, Route, Link } from 'react-router-dom';
// import { ActivateDeactivate } from './components/ActivateDeactivate';
// import { Greeter } from './components/Greeter';
// import { SectionDivider } from './components/SectionDivider';
// import { SignMessage } from './components/SignMessage';
// import { WalletStatus } from './components/WalletStatus';
// import { LoginPage } from './components/LoginPage';
// const StyledAppDiv = styled.div`
//   display: grid;
//   grid-gap: 20px;
// `;
// export function App(): ReactElement {
//   return (
//     <Router>
//       <StyledAppDiv>
//         <nav>
//           <ul>
//             <li>
//               <Link to="/">ActivateDeactivate</Link>
//             </li>
//             <li>
//               <Link to="/wallet-status">WalletStatus</Link>
//             </li>
//             <li>
//               <Link to="/sign-message">SignMessage</Link>
//             </li>
//             <li>
//               <Link to="/greeter">Greeter</Link>
//             </li>
//           </ul>
//         </nav>
//         <Routes>
//           <Route path="/" element={<LoginPage />} />
//           <Route path="/wallet-status" element={<WalletStatus />} />
//           <Route path="/sign-message" element={<SignMessage />} />
//           <Route path="/greeter" element={<Greeter />} />
//           {/* If you have a not found page or want to redirect to a default, you can use a Route like this */}
//           {/* <Route path="*" element={<NotFoundComponent />} /> */}
//         </Routes>
//       </StyledAppDiv>
//     </Router>
//   );
// }
// App.tsx

import React from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { HomePage } from './components/HomePage';
import { LoginPage } from './components/LoginPage';
import { useWeb3React } from '@web3-react/core';
import { useEffect } from 'react';
import { useAppDispatch } from './hooks'; 
import { setCardImageMap } from './store/cardImageMapSlice';
import { fetchUserData, fetchCardImageMap } from './store/mockBackend';
import { setAddress, setRemainingDraws, setCollection } from './store/userSlice';
import { getBalance, getUserCollection } from './store/interact';
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
          const balance = await getBalance(account?account:"");
          const collections = await getUserCollection((account?account:""))
          console.log(balance,"HomePageBalance")
          dispatch(setRemainingDraws(balance));
          dispatch(setCollection(collections));

          const cardImageMapData = await fetchCardImageMap();
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
