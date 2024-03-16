import { ReactElement } from 'react';
import styled from 'styled-components';
import { BrowserRouter as Router, Routes, Route, Link } from 'react-router-dom';
import { ActivateDeactivate } from './components/ActivateDeactivate';
import { Greeter } from './components/Greeter';
import { SectionDivider } from './components/SectionDivider';
import { SignMessage } from './components/SignMessage';
import { WalletStatus } from './components/WalletStatus';

const StyledAppDiv = styled.div`
  display: grid;
  grid-gap: 20px;
`;
export function App(): ReactElement {
  return (
    <Router>
      <StyledAppDiv>
        <nav>
          <ul>
            <li>
              <Link to="/">ActivateDeactivate</Link>
            </li>
            <li>
              <Link to="/wallet-status">WalletStatus</Link>
            </li>
            <li>
              <Link to="/sign-message">SignMessage</Link>
            </li>
            <li>
              <Link to="/greeter">Greeter</Link>
            </li>
          </ul>
        </nav>
        <Routes>
          <Route path="/" element={<ActivateDeactivate />} />
          <Route path="/wallet-status" element={<WalletStatus />} />
          <Route path="/sign-message" element={<SignMessage />} />
          <Route path="/greeter" element={<Greeter />} />
          {/* If you have a not found page or want to redirect to a default, you can use a Route like this */}
          {/* <Route path="*" element={<NotFoundComponent />} /> */}
        </Routes>
      </StyledAppDiv>
    </Router>
  );
}
