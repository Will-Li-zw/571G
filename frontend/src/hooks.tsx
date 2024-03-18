// src/hooks.ts
import { useDispatch } from 'react-redux';
import { AppDispatch } from './store/store';

// Typed useDispatch hook
export const useAppDispatch = () => useDispatch<AppDispatch>();
