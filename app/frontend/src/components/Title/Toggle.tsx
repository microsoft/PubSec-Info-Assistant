import React from 'react';

// export const ToggleContext = React.createContext({
//     toggle: 'Work', // default value
//     setToggle: (value: (prevToggle: string) => string) => {}, 
//   });

export const ToggleContext = React.createContext({
  toggle: 'Work',
  setToggle: (value: (prevToggle: string) => string) => {},
});