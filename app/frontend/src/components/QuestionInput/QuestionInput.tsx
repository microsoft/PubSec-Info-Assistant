// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

import { useState } from "react";
import { Stack, TextField } from "@fluentui/react";
import { Send28Filled, Broom28Filled } from "@fluentui/react-icons";
import { RAIPanel } from "../RAIPanel";

import styles from "./QuestionInput.module.css";
import { Button } from "react-bootstrap";

interface Props {
    onSend: (question: string) => void;
    disabled: boolean;
    placeholder?: string;
    clearOnSend?: boolean;
    onAdjustClick?: () => void;
    showClearChat?: boolean;
    onClearClick?: () => void;
    onRegenerateClick?: () => void;
}

export const QuestionInput = ({ onSend, disabled, placeholder, clearOnSend, onAdjustClick, showClearChat, onClearClick, onRegenerateClick }: Props) => {
    const [question, setQuestion] = useState<string>("");

    const sendQuestion = () => {
        if (disabled || !question.trim()) {
            return;
        }

        onSend(question);

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

    return (
        <Stack>
            <Stack.Item>
            <Stack horizontal className={styles.questionInputContainer}>
                {showClearChat ? (
                    <div className={styles.questionClearButtonsContainer}>
                        <div
                            className={styles.questionClearChatButton}
                            aria-label="Clear chat button"
                            onClick={onClearClick}
                            onMouseEnter={onMouseEnter}
                            onMouseLeave={onMouseLeave}
                        >
                            <Broom28Filled primaryFill="rgba(255, 255, 255, 1)" />
                            <span id={"test"} hidden={clearChatTextEnabled}>Clear Chat</span>
                        </div>
                    </div>
                )
                : null}
                <TextField
                    className={styles.questionInputTextArea}
                    placeholder={placeholder}
                    multiline
                    resizable={false}
                    borderless
                    value={question}
                    onChange={onQuestionChange}
                    onKeyDown={onEnterPress}
                />
                <div className={styles.questionInputButtonsContainer}>
                    <div
                        className={`${styles.questionInputSendButton} ${sendQuestionDisabled ? styles.questionInputSendButtonDisabled : ""}`}
                        aria-label="Ask question button"
                        onClick={sendQuestion}
                    >
                        <Send28Filled primaryFill="rgba(115, 118, 225, 1)" />
                    </div>
                </div>
            </Stack>
            </Stack.Item>
            <Stack.Item align="center">
                <RAIPanel onAdjustClick={onAdjustClick} onRegenerateClick={onRegenerateClick} />
            </Stack.Item>
        </Stack>
    );
};
