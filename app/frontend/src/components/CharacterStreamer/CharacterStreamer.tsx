import React, { useState, useEffect, useRef } from 'react';
import ReactMarkdown from 'react-markdown';
import { Approaches, ChatResponse } from '../../api';
import readNDJSONStream from "ndjson-readablestream";
import rehypeRaw from 'rehype-raw';
import rehypeSanitize from 'rehype-sanitize';

const CharacterStreamer = ({ eventSource, nonEventString, onStreamingComplete, classNames, typingSpeed = 30, readableStream, setAnswer, approach = Approaches.ChatWebRetrieveRead, setError }:
   { readableStream?: ReadableStream, setAnswer?: (data: ChatResponse) => void, eventSource?: any; nonEventString?: string, onStreamingComplete: any; classNames?: string; typingSpeed?: number, approach?: Approaches, setError?: (data: string) => void}) => {
  const [output, setOutput] = useState('');
  const [isLoading, setIsLoading] = useState(true);
  const queueRef = useRef<string[]>([]); // Now TypeScript knows this is an array of strings
  const processingRef = useRef(false);
  const chatMessageStreamEnd = useRef<HTMLDivElement | null>(null);
  const [dots, setDots] = useState('');

    const handleStream = async () => {
      try {
        var response = {} as ChatResponse
        if (readableStream && !readableStream.locked) {
          for await (const event of readNDJSONStream(readableStream)) {
            if (event["data_points"]) {
                response = {
                    answer: "",
                    thoughts: event["thoughts"],
                    data_points: event["data_points"],
                    approach: approach,
                    thought_chain: {
                        "work_response": event["thought_chain"]["work_response"],
                        "web_response": event["thought_chain"]["web_response"]
                    },
                    work_citation_lookup: event["work_citation_lookup"],
                    web_citation_lookup: event["web_citation_lookup"]
                }
            }
            else if (event["content"]) {
                response.answer += event["content"]
                queueRef.current = queueRef.current.concat(event["content"].split(''));
                if (!processingRef.current) {
                  processQueue();
                }
            }
            else if (event["error"]) {
                if (setError) {
                  setError(event["error"])
                  return
                }
                else {
                  console.error(event["error"])
                  return
                }
            }
          }
          if (setAnswer) {
            // We need to set these values in the thought_chain so that the compare works
            if (approach === Approaches.ChatWebRetrieveRead) {
              response.thought_chain["web_response"] = response.answer
            }
            else if (approach === Approaches.ReadRetrieveRead) {
              response.thought_chain["work_response"] = response.answer
            }
            else if (approach === Approaches.GPTDirect) {
              response.thought_chain["ungrounded_response"] = response.answer
            }
            else if (approach === Approaches.CompareWebWithWork) {
              response.thought_chain["web_to_work_comparison_response"] = response.answer
            }
            else if (approach === Approaches.CompareWorkWithWeb) {
              response.thought_chain["work_to_web_comparison_response"] = response.answer
            }

            setAnswer(response)
          }
        }
      }
      catch (e : any) {
        if (e.name !== 'AbortError')
          {
            console.error(e);
          }
      }
    }

    if (readableStream) {
        handleStream();
    }

  useEffect(() => {
    const intervalId = setInterval(() => {
      setDots(prevDots => (prevDots.length < 3 ? prevDots + '.' : ''));
    }, 500); // Change dot every 500ms

    return () => clearInterval(intervalId); // Cleanup interval on component unmount
  }, [isLoading]);

  useEffect(() => {
      chatMessageStreamEnd.current?.scrollIntoView({ behavior: "smooth" });
    }, [output]);

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
    setIsLoading(false);
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

  return isLoading ? <div className={classNames}>Generating Answer{dots}</div> : 
        <div className={classNames}><ReactMarkdown children={output} rehypePlugins={[rehypeRaw, rehypeSanitize]}></ReactMarkdown>
        <div ref={chatMessageStreamEnd} /></div>;
};

export default CharacterStreamer;
