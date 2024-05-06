// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

import { useMemo } from "react";
import { Stack, IconButton } from "@fluentui/react";
import { ShieldCheckmark20Regular } from '@fluentui/react-icons';
import DOMPurify from "dompurify";

import styles from "./Answer.module.css";

import { Approaches, ChatResponse, getCitationFilePath, ChatMode } from "../../api";
import { parseAnswerToHtml } from "./AnswerParser";
import { AnswerIcon } from "./AnswerIcon";
import { RAIPanel } from "../RAIPanel";
import CharacterStreamer from "../CharacterStreamer/CharacterStreamer";

interface Props {
    answer: ChatResponse;
    isSelected?: boolean;
    onCitationClicked: (filePath: string, sourcePath: string, pageNumber: string) => void;
    onThoughtProcessClicked: () => void;
    onWebSearchClicked: () => void;
    onRagSearchClicked: () => void;
    onWebCompareClicked: () => void;
    onRagCompareClicked: () => void;
    onSupportingContentClicked: () => void;
    onFollowupQuestionClicked?: (question: string) => void;
    showFollowupQuestions?: boolean;
    onAdjustClick?: () => void;
    onRegenerateClick?: () => void;
    chatMode: ChatMode;
    answerStream: ReadableStream | undefined;
    setAnswer?: (data: ChatResponse) => void;
}

export const Answer = ({
    answer,
    isSelected,
    onCitationClicked,
    onThoughtProcessClicked,
    onWebSearchClicked,
    onRagSearchClicked,
    onWebCompareClicked,
    onRagCompareClicked,
    onSupportingContentClicked,
    onFollowupQuestionClicked,
    showFollowupQuestions,
    onAdjustClick,
    onRegenerateClick,
    chatMode,
    answerStream,
    setAnswer
}: Props) => {
    const parsedAnswer = useMemo(() => parseAnswerToHtml(answer.answer, answer.approach, answer.work_citation_lookup, answer.web_citation_lookup, answer.thought_chain, onCitationClicked), [answer]);

    const sanitizedAnswerHtml = DOMPurify.sanitize(parsedAnswer.answerHtml);

    return (
        <Stack className={`${answer.approach == Approaches.ReadRetrieveRead ? styles.answerContainerWork : 
                            answer.approach == Approaches.ChatWebRetrieveRead ? styles.answerContainerWeb :
                            answer.approach == Approaches.CompareWorkWithWeb || answer.approach == Approaches.CompareWebWithWork ? styles.answerContainerCompare :
                            answer.approach == Approaches.GPTDirect ? styles.answerContainerUngrounded :
                            styles.answerContainer} ${isSelected && styles.selected}`} verticalAlign="space-between">
            <Stack.Item>
                <Stack horizontal horizontalAlign="space-between">
                    <AnswerIcon approach={answer.approach} />
                    <div>
                        {answer.approach != Approaches.GPTDirect && 
                            <IconButton
                                style={{ color: "black" }}
                                iconProps={{ iconName: "Lightbulb" }}
                                title="Show thought process"
                                ariaLabel="Show thought process"
                                onClick={() => onThoughtProcessClicked()}
                                disabled={!answer.thoughts}
                            />
                        }
                        {answer.approach == Approaches.ReadRetrieveRead &&
                            <IconButton
                                style={{ color: "black" }}
                                iconProps={{ iconName: "ClipboardList" }}
                                title="Show supporting content"
                                ariaLabel="Show supporting content"
                                onClick={() => onSupportingContentClicked()}
                                disabled={!answer.data_points || !answer.data_points.length}
                            />
                        }
                    </div>
                </Stack>
            </Stack.Item>

            <Stack.Item grow>
                {(answer.approach != Approaches.GPTDirect) &&
                    <div className={styles.protectedBanner}>
                        <ShieldCheckmark20Regular></ShieldCheckmark20Regular>Your personal and company data are protected
                    </div>
                }
                { answer.answer && <div className={answer.approach == Approaches.GPTDirect ? styles.answerTextUngrounded : styles.answerText} dangerouslySetInnerHTML={{ __html: sanitizedAnswerHtml }}></div> }
                {!answer.answer && <CharacterStreamer classNames={answer.approach == Approaches.GPTDirect ? styles.answerTextUngrounded : styles.answerText} readableStream={answerStream} setAnswer={setAnswer} onStreamingComplete={() => {}} typingSpeed={10} /> }
            </Stack.Item>

            {(parsedAnswer.approach == Approaches.ChatWebRetrieveRead && !!parsedAnswer.web_citations.length) && (
                <Stack.Item>
                    <Stack horizontal wrap tokens={{ childrenGap: 5 }}>
                        <span className={styles.citationLearnMore}>Citations:</span>
                        {parsedAnswer.web_citations.map((x, i) => {
                            const path = getCitationFilePath(x);
                            return (
                                <a key={i} className={styles.citationWeb} 
                                title={x} href={x} target="_blank" rel="noopener noreferrer">
                                {`${++i}. ${x}`}
                                </a>
                            );
                        })}
                    </Stack>
                </Stack.Item>
                
            )}
            {(parsedAnswer.approach == Approaches.ReadRetrieveRead && !!parsedAnswer.work_citations.length) && (
                <Stack.Item>
                    <Stack horizontal wrap tokens={{ childrenGap: 5 }}>
                        <span className={styles.citationLearnMore}>Citations:</span>
                        {parsedAnswer.work_citations.map((x, i) => {
                            const path = getCitationFilePath(x);
                            return ( 
                                 <a key={i} className={styles.citationWork} 
                                 title={x} onClick={() => onCitationClicked(path, (parsedAnswer.work_sourceFiles as any)[x], (parsedAnswer.pageNumbers as any)[x])}>
                                 {`${++i}. ${x}`}
                                </a>
                            );
                        })}
                    </Stack>
                </Stack.Item>
            )}
            {parsedAnswer.approach == Approaches.CompareWebWithWork && (
                <div>
                    <Stack.Item>
                        <Stack horizontal wrap tokens={{ childrenGap: 5 }}>
                            <span className={styles.citationLearnMore}>Web Citations:</span>
                            {parsedAnswer.web_citations.map((x, i) => {
                                const path = getCitationFilePath(x);
                                return (
                                    <a key={i} className={styles.citationWeb} 
                                    title={x} href={x} target="_blank" rel="noopener noreferrer">
                                    {`${++i}. ${x}`}
                                    </a>
                                );
                            })}
                        </Stack>
                    </Stack.Item>
                    <div style={{ width: "100%", margin: "10px 0" }}></div>
                    <Stack.Item>
                        <Stack horizontal wrap tokens={{ childrenGap: 5 }}>
                            <span className={styles.citationLearnMore}>Work Citations:</span>
                            {parsedAnswer.work_citations.map((x, i) => {
                                const path = getCitationFilePath(x);
                                return ( 
                                    <a key={i} className={styles.citationWork} 
                                    title={x} onClick={() => onCitationClicked(path, (parsedAnswer.work_sourceFiles as any)[x], (parsedAnswer.pageNumbers as any)[x])}>
                                    {`${++i}. ${x}`}
                                    </a>
                                );
                            })}
                        </Stack>
                    </Stack.Item>
                </div>
            )}
            {parsedAnswer.approach == Approaches.CompareWorkWithWeb && (
                <div>
                    <Stack.Item>
                        <Stack horizontal wrap tokens={{ childrenGap: 5 }}>
                            <span className={styles.citationLearnMore}>Work Citations:</span>
                            {parsedAnswer.work_citations.map((x, i) => {
                                const path = getCitationFilePath(x);
                                return ( 
                                    <a key={i} className={styles.citationWork} 
                                    title={x} onClick={() => onCitationClicked(path, (parsedAnswer.work_sourceFiles as any)[x], (parsedAnswer.pageNumbers as any)[x])}>
                                    {`${++i}. ${x}`}
                                    </a>
                                );
                            })}
                        </Stack>
                    </Stack.Item>
                    <Stack.Item>
                        <Stack horizontal wrap tokens={{ childrenGap: 5 }}>
                            <span className={styles.citationLearnMore}>Web Citations:</span>
                            {parsedAnswer.web_citations.map((x, i) => {
                                const path = getCitationFilePath(x);
                                return (
                                    <a key={i} className={styles.citationWeb} 
                                    title={x} href={x} target="_blank" rel="noopener noreferrer">
                                    {`${++i}. ${x}`}
                                    </a>
                                );
                            })}
                        </Stack>
                    </Stack.Item>
                </div>
            )}
            
            {!!parsedAnswer.followupQuestions.length && showFollowupQuestions && onFollowupQuestionClicked && (
                <Stack.Item>
                    <Stack horizontal wrap className={`${!!parsedAnswer.work_citations.length ? styles.followupQuestionsList : !!parsedAnswer.web_citations.length ? styles.followupQuestionsList : ""}`} tokens={{ childrenGap: 6 }}>
                        <span className={styles.followupQuestionLearnMore}>Follow-up questions:</span>
                        {parsedAnswer.followupQuestions.map((x, i) => {
                            return (
                                <a key={i} className={styles.followupQuestion} title={x} onClick={() => onFollowupQuestionClicked(x)}>
                                    {`${x}`}
                                </a>
                            );
                        })}
                    </Stack>
                </Stack.Item>
            )}
            <Stack.Item>
                <div className={styles.raiwarning}>AI-generated content may be incorrect</div>
            </Stack.Item>
            <Stack.Item align="center">
                <RAIPanel approach={answer.approach} chatMode={chatMode} onAdjustClick={onAdjustClick} onRegenerateClick={onRegenerateClick} onWebSearchClicked={onWebSearchClicked} onWebCompareClicked={onWebCompareClicked} onRagCompareClicked={onRagCompareClicked} onRagSearchClicked={onRagSearchClicked} />
            </Stack.Item>
        </Stack>
    );
};
