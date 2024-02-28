import React from 'react';

export const ToggleContext = React.createContext({
    toggle: 'Work', // default value
    setToggle: (value: (prevToggle: string) => string) => {}, 
  });