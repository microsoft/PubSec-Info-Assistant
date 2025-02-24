// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.
import React, { useState, useEffect } from 'react';
import { Stack, TextField } from "@fluentui/react";
import { Send28Filled, Broom28Filled } from "@fluentui/react-icons";
import { RAIPanel } from "../RAIPanel";
import StatusMessage  from '../StatusMessage/StatusMessage';
import styles from "./QuestionInput.module.css";
import { Button } from "react-bootstrap";


interface Props {
    onSend: (question: string) => void;
    disabled: boolean;
    placeholder?: string;
    clearOnSend?: boolean;
    onAdjustClick?: () => void;
    onInfoClick?: () => void;
    showClearChat?: boolean;
    onClearClick?: () => void;
    onRegenerateClick?: () => void;
}

export const QuestionInput = ({ onSend, disabled, placeholder, clearOnSend, onAdjustClick, showClearChat, onClearClick, onRegenerateClick }: Props) => {
    const [question, setQuestion] = useState<string>("");
    const [status, setStatus] = useState('');
    const [isSmallScreen, setIsSmallScreen] = useState<boolean>(window.innerWidth <= 768);
    const [liveMessage, setLiveMessage] = useState("");

    const sendQuestion = () => {
        if (disabled || !question.trim()) {
            return;
        }

        onSend(question);
        setStatus('Question sent successfully.');

        if (clearOnSend) {
            setQuestion("");
        }
    };

    const onEnterPress = (ev: React.KeyboardEvent<Element>) => {
        if (ev.key === "Enter" && !ev.shiftKey) {
            ev.preventDefault();
            sendQuestion();
        }
    };

    const onQuestionChange = (_ev: React.FormEvent<HTMLInputElement | HTMLTextAreaElement>, newValue?: string) => {
        if (!newValue) {
            setQuestion("");
        } else if (newValue.length <= 1000) {
            setQuestion(newValue);
        }
    };

    const sendQuestionDisabled = disabled || !question.trim();

    const [clearChatTextEnabled, setClearChatTextEnable] = useState<boolean>(true); 
    
    const onMouseEnter = () => {
        setClearChatTextEnable(false);
    }

    const onMouseLeave = () => {
        setClearChatTextEnable(true);
    }
    const handleKeyDown = (event: React.KeyboardEvent<Element>, onClick: () => void) => {
        if (event.key === "Enter") {
            onClick();
        }
    };
    const textFieldStyles = {
        fieldGroup: {
            minHeight: isSmallScreen ? '20px' : '60px'// Customize border color

            
        },
        field: {
            fontSize: isSmallScreen ? '0.43rem' : '16px',
            height: isSmallScreen ? '2.5rem' : '60px'
             // Customize line height
        },
        textArea: {
            fontSize: isSmallScreen ? '0.4rem' : '16px',
            height: isSmallScreen ? '2rem' : '60px' // Customize text color
        }
    };
    useEffect(() => {
        window.addEventListener('resize', handleResize);
        return () => {
            window.removeEventListener('resize', handleResize);
        };
    }, []);
    const handleResize = () => {
        setIsSmallScreen(window.innerWidth <= 768);
    };
    const handleSendQuestion = () => {
        sendQuestion();
        setLiveMessage("Message has been sent");
    };
    return (
        <Stack>
            <Stack.Item>
            <Stack horizontal className={styles.questionInputContainer}>
                <TextField
                    className={styles.questionInputTextArea}
                    placeholder={placeholder}
                    multiline
                    resizable={false}
                    borderless
                    value={question}
                    onChange={onQuestionChange}
                    onKeyDown={onEnterPress}
                    styles={textFieldStyles}
                />
                <div className={styles.questionInputButtonsContainer}>
                    <div role="button"
                        className={`${styles.questionInputSendButton} ${sendQuestionDisabled ? styles.questionInputSendButtonDisabled : ""}`}
                        aria-label="Ask question button"
                        onClick={handleSendQuestion}
                        tabIndex={0}
                        onKeyDown={(event) => handleKeyDown(event, sendQuestion)}
                    >
                        <Send28Filled primaryFill="rgba(115, 118, 225, 1)" />
                    </div>
                    <StatusMessage message={status} />
                    <div aria-live="assertive" aria-atomic="true" className={styles.visuallyHidden}>
                        {liveMessage}
                    </div>
                </div>
            </Stack>
            </Stack.Item>
            <Stack.Item align="center">
                <RAIPanel onAdjustClick={onAdjustClick} onRegenerateClick={onRegenerateClick} tabIndex={0} />
            </Stack.Item>
        </Stack>
    );
};
