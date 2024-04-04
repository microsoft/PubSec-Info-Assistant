// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

import React from 'react';
//import { Button } from '@fluentui/react';
import { Accordion, Card, Button } from 'react-bootstrap';
import {getHint, processAgentResponse, getSolve, streamData} from "../../api";
import { useEffect, useState } from "react";
import styles from './Tutor.module.css';
import ReactMarkdown from 'react-markdown';
import { MathFormatProfessionalFilled } from '@fluentui/react-icons';
import { Example, ExampleModel } from '../../components/Example';
import estyles from "../../components/Example/Example.module.css";

const Tutor = () => {
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState(false);
    const [errorMessage, setErrorMessage] = useState('');
    const [mathProblem, setMathProblem] = useState('');
    const [output, setOutput] = useState(['']);
    //const [output, setOutput] = useState<string | null>("");
    const [selectedButton, setSelectedButton] = useState<string | null>(null);

    enum ButtonValues {
        Clues = "Give Me Clues",
        Solve = "Show Me How to Solve It",
        Answer = "Show Me the Answer"
    }

    const handleInput = (event: React.FormEvent<HTMLFormElement>) => {
        event.preventDefault();
        setLoading(true);
        userInput(mathProblem);
    };

    const userInput = (problem: string) => {
        // Process the user's math problem here
        console.log(problem);
        setLoading(false);
    };
    async function hinter(question: string) {
        try {
            setOutput(['']);
            setLoading(true);
            const hint: String = await getHint(question);
            setLoading(false);
            setOutput([hint.toString()]);
            console.log(hint);
        } catch (error) {
            console.log(error);
        }
    }
    
    async function getAnswer(question: string) {
        setOutput(null);
        setError(false);
        setLoading(true);
        await processAgentResponse(question).then((response) => {
            setLoading(false);
            setOutput(response.toString());
        }).catch(error => {
            setLoading(false);
            setErrorMessage(error.message);
            setError(true);
        });
        // const eventSource = await processAgentResponse(question);
        // eventSource.onmessage = function(event) {
        //     console.log(event.data);
        //     setOutput(event.data);
    };
    const [eventSource, setEventSource] = useState<EventSource | null>(null);

    const handleButton2Click = () => {
        setOutput(['']);
        setLoading(true);
        setSelectedButton('button2');
        if (eventSource) {
          eventSource.close();
        }
        const newEventSource = streamData(mathProblem, (data) => {
            setLoading(false);  
            setOutput((prevOutput) => [...prevOutput, data]);

        });
        setEventSource(newEventSource);
      };
  
    useEffect(() => {
      return () => {
        if (eventSource) {
          eventSource.close();
        }
      };
    }, [eventSource]);

    async function handleExampleClick(value: string) {
        setMathProblem(value);
        getAnswer(value);
    }

    
const EXAMPLES: ExampleModel[] = [
    { text: "Determine the slope of the line passing through the points (2,5)(2,5) and (4,9)(4,9)", value: "Determine the slope of the line passing through the points (2,5)(2,5) and (4,9)(4,9)" },
    { text: "Calculate the result of (9+3)×4−7", value: "Calculate the result of (9+3)×4−7" },
    { text: "What's the answer for (4.5*2.1)^2.2?", value: "What's the answer for (4.5*2.1)^2.2?" },
    { text: "Find the mean of the heights of students in centimeters: 160, 165, 170, 175, 180.", value: "The heights (in centimeters) of students in a class are recorded as follows: 160, 165, 170, 175, 180. Find the mean height of the students." }
];


return (
    <div className={styles.App}>
    <MathFormatProfessionalFilled fontSize={"6rem"} primaryFill={"#8A0B31"} aria-hidden="true" aria-label="Supported File Types" />
    <h1 className={styles.title}>Math Assistant</h1>
    <span className={styles.chatEmptyObjectives}>
      <i className={styles.centered}>Information Assistant uses AI. Check for mistakes.</i> <a href="https://github.com/microsoft/PubSec-Info-Assistant/blob/main/docs/transparency.md" target="_blank" rel="noopener noreferrer"> Transparency Note</a>
    </span>
    <div className={styles.centeredContainer}>
    <p>Select an example query:</p>
    <div >
        <ul className={estyles.examplesNavList}>
            {EXAMPLES.map((x, i) => (
                <li key={i}>
                    <Example text={x.text} value={x.value} onClick={handleExampleClick} />
                </li>
            ))}
        </ul>
    </div >
        <form className={styles.formClass} onSubmit={handleInput}>
            <p className={styles.inputLabel}>Enter question:</p>
            <input
                className={styles.inputField}
                type="text"
                value={mathProblem}
                onChange={(e) => setMathProblem(e.target.value)}
                placeholder="Enter question:"
            />
            <div className={styles.buttonContainer}>
            <Button variant="secondary"
                className={selectedButton === 'button1' ? styles.selectedButton : ''}
                onClick={() => {
                    setSelectedButton('button1');
                    hinter(mathProblem);
                }}
            >
                {ButtonValues.Clues}
            </Button>
            <Button variant="secondary"
                className={selectedButton === 'button2' ? styles.selectedButton : ''}
                onClick={() => {
                    setSelectedButton('button2');
                    // solver(mathProblem);
                    handleButton2Click();
                }}
            >
                {ButtonValues.Solve}
            </Button>
            <Button variant="secondary"
                className={selectedButton === 'button3' ? styles.selectedButton : ''}
                onClick={() => {
                    setSelectedButton("button3");
                    getAnswer(mathProblem);
                }}
            >
                {ButtonValues.Answer}
            </Button>
        </div>
        </form>
        {loading && <div className="spinner">Loading...</div>}
        {error && <div className="spinner">{errorMessage}</div>}
        {output && 
                <Accordion defaultActiveKey="0">
                    
                    <h2>
                        Math Assistant Response:
                    </h2>
                    <Accordion.Collapse eventKey="0">
                        <div>
                        {output.map((item, index) => (
                        <ReactMarkdown key={index} children={item} />
                        ))}
                    </div>
                    </Accordion.Collapse>                    
                </Accordion>
            }
    </div>
    </div>
)
};

export default Tutor; // Export the 'Chat' component
