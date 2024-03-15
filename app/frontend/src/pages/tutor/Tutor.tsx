// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

import React from 'react';
import { Accordion, AccordionContent, AccordionTitle } from '@fluentui/react-northstar';
import { getStreamlitURI, GetStreamlitURIResponse, getHint, processAgentResponse, getSolve} from "../../api";
import { useEffect, useState } from "react";

const Tutor = () => {
    const [StreamlitURI, setStreamlitURI] = useState<GetStreamlitURIResponse | null>(null);
    const [loading, setLoading] = useState(false);
    const [mathProblem, setMathProblem] = useState('');
    const [output, setOutput] = useState<string | null>(null);

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

    async function fetchStreamlitURI() {
        console.log("Streamlit URI 1");
        try {
            const fetchedStreamlitURI = await getStreamlitURI();
            setStreamlitURI(fetchedStreamlitURI);
            console.log("Streamlit URI 2", fetchedStreamlitURI)
        } catch (error) {
            // Handle the error here
            console.log(error);
        }
    }
    async function hinter(question: string) {
        try {
            setOutput(null);
            setLoading(true);
            const hint: String = await getHint(question);
            setLoading(false);
            setOutput(hint.toString());
            console.log(hint);
        } catch (error) {
            console.log(error);
        }
        
    }
    async function solver(question: string) {
        setLoading(true);
        setOutput(null);
        try {
            const solve = await getSolve(question);
            let outputString = '';
            solve.forEach((item) => {
                outputString += item + '\n';
                console.log(item);
            });
            setOutput(outputString);
        } catch (error) {
            console.log(error);
        } finally {
            setLoading(false);
        }
        
    }
    
    async function getAnswer(question: string) {
        setOutput(null);
        const eventSource = await processAgentResponse(question);
        eventSource.onmessage = function(event) {
            console.log(event.data);
            setOutput(event.data);
    };
}

    useEffect(() => {
        fetchStreamlitURI();
    }, []);
    const StreamlitURIf = (StreamlitURI?.STREAMLIT_HOST_URI ?? '') + ':8051';
    console.log("Streamlit URI 3", StreamlitURIf)
return (
    <div>
            <form onSubmit={handleInput}>
                <input
                    type="text"
                    value={mathProblem}
                    onChange={(e) => setMathProblem(e.target.value)}
                    placeholder="Enter question:"
                />
                <button type="submit" onClick={() => hinter(mathProblem)}>Give me clues</button>
                <button type="submit"onClick={() => solver(mathProblem)}>Show me how to solve it</button>
                <button type="submit" onClick={() => getAnswer(mathProblem)}>Show me the answer</button>
            </form>
            {loading && <div className="spinner">Loading...</div>}
            <Accordion>
                {output && <AccordionTitle content="Math Tutor Response"/>}
                {output && <AccordionContent>{output}</AccordionContent>}
            </Accordion>
        </div>

)
};

export default Tutor; // Export the 'Chat' component
