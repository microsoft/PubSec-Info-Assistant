import React, { useState, useEffect, useRef } from 'react';
import ReactMarkdown from 'react-markdown';

const CharacterStreamer = ({ eventSource, nonEventString, onStreamingComplete, classNames, typingSpeed = 30 }: { eventSource?: any; nonEventString?: string, onStreamingComplete: any; classNames?: string; typingSpeed?: number }) => {
  const [output, setOutput] = useState('');
  const queueRef = useRef<string[]>([]); // Now TypeScript knows this is an array of strings
  const processingRef = useRef(false);

  useEffect(() => {
    if (!eventSource && nonEventString) {
        console.log("Event source not found");
        queueRef.current = queueRef.current.concat(nonEventString.split(''));
        if (!processingRef.current) {
            processQueue();
        }
    }
    const handleMessage = async (event: MessageEvent) => {
        // Process the Markdown content to HTML immediately
        //const processedHTML = await marked(event.data);
        // Split the processed HTML into an array of characters and add it to the queue
        // We use markdown, <br> does nothing for us. We need to replace it with \n
        const processedHTML = event.data.replace(/<br>/g, '\n');
        queueRef.current = queueRef.current.concat(processedHTML.split(''));
        queueRef.current = queueRef.current.concat("\n\n");
        if (!processingRef.current) {
            processQueue();
        }
    };

    if (eventSource) {
        eventSource.addEventListener('message', handleMessage);
        eventSource.addEventListener('end', onStreamingComplete);
    }

    return () => {
        if (eventSource) {
            eventSource.removeEventListener('message', handleMessage);
            eventSource.removeEventListener('end', onStreamingComplete);
        }
    };
  }, [eventSource, nonEventString]);

  const processQueue = () => {
    processingRef.current = true;
    const intervalId = setInterval(() => {
      if (queueRef.current.length > 0) {
        const char = queueRef.current.shift();
        setOutput((prevOutput) => prevOutput + char);
      } else {
        clearInterval(intervalId);
        processingRef.current = false;
      }
    }, typingSpeed); // Adjust based on desired "typing" speed
  };

  return <div className={classNames}><ReactMarkdown>{output}</ReactMarkdown></div>;
};

export default CharacterStreamer;
