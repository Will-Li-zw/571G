import { ReactElement } from 'react';
import styled from 'styled-components';
import { useWeb3React } from '@web3-react/core';
import { injected } from '../utils/connectors';
import { useEagerConnect, useInactiveListener } from '../utils/hooks';

const LoginPageDiv = styled.div`
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  height: 100vh;
`;

const Logo = styled.div`
  /* Add styles for your logo here */
`;

const ProjectName = styled.h1`
  margin: 20px 0;
`;

const LoginButton = styled.button`
  width: 200px;
  height: 40px;
  border-radius: 20px;
  font-size: 1rem;
  cursor: pointer;
  border: 2px solid black; /* Change as needed */
  &:hover {
    background-color: #f0f0f0; /* Change as needed */
  }
`;

export function LoginPage(): ReactElement {
  const { activate, active } = useWeb3React();
//   console.log(active)

  // Automatically try to connect to MetaMask
//   useEagerConnect();

  // Handle the connection manually when the user clicks the button
  const handleLoginClick = async () => {
    try {
      await activate(injected);
    } catch (error) {
      console.error('Error on logging in:', error);
    }
  };

  useInactiveListener(!active);

  return (
    <LoginPageDiv>
      <Logo>Logo</Logo>
      <ProjectName>Your Project Name</ProjectName>
      <LoginButton onClick={handleLoginClick} disabled={active}>
        {active ? 'Connected' : 'Login with MetaMask'}
      </LoginButton>
    </LoginPageDiv>
  );
}
