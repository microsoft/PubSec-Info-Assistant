import React from 'react';
import { clearAnnouncer, announce } from '@react-aria/live-announcer';

import { useEffect } from 'react';

interface StatusMessageProps {
  message: string;
}

const StatusMessage: React.FC<StatusMessageProps> = ({ message }) => {
  useEffect(() => {
    announce(message);
  }, [message]);

  return null;
};

export default StatusMessage;