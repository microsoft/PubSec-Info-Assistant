// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

import { useRef, useState, useEffect } from "react";
import { Checkbox, Panel, DefaultButton, TextField, SpinButton, Separator, Toggle, Label } from "@fluentui/react";
import Switch from 'react-switch';
import { GlobeFilled, BuildingMultipleFilled, AddFilled, ChatSparkleFilled } from "@fluentui/react-icons";
import { ITag } from '@fluentui/react/lib/Pickers';

import styles from "./Chat.module.css";
import rlbgstyles from "../../components/ResponseLengthButtonGroup/ResponseLengthButtonGroup.module.css";
import rtbgstyles from "../../components/ResponseTempButtonGroup/ResponseTempButtonGroup.module.css";

import { chatApi, Approaches, ChatResponse, ChatRequest, ChatTurn, ChatMode, getFeatureFlags, GetFeatureFlagsResponse } from "../../api";
import { Answer, AnswerError, AnswerLoading } from "../../components/Answer";
import { QuestionInput } from "../../components/QuestionInput";
import { ExampleList } from "../../components/Example";
import { UserChatMessage } from "../../components/UserChatMessage";
import { AnalysisPanel, AnalysisPanelTabs } from "../../components/AnalysisPanel";
import { SettingsButton } from "../../components/SettingsButton";
import { InfoButton } from "../../components/InfoButton";
import { ClearChatButton } from "../../components/ClearChatButton";
import { ResponseLengthButtonGroup } from "../../components/ResponseLengthButtonGroup";
import { ResponseTempButtonGroup } from "../../components/ResponseTempButtonGroup";
import { ChatModeButtonGroup } from "../../components/ChatModeButtonGroup";
import { InfoContent } from "../../components/InfoContent/InfoContent";
import { FolderPicker } from "../../components/FolderPicker";
import { TagPickerInline } from "../../components/TagPicker";
import React from "react";

const Chat = () => {
    const [isConfigPanelOpen, setIsConfigPanelOpen] = useState(false);
    const [isInfoPanelOpen, setIsInfoPanelOpen] = useState(false);
    const [retrieveCount, setRetrieveCount] = useState<number>(5);
    const [useSuggestFollowupQuestions, setUseSuggestFollowupQuestions] = useState<boolean>(false);
    const [userPersona, setUserPersona] = useState<string>("analyst");
    const [systemPersona, setSystemPersona] = useState<string>("an Assistant");
    // Setting responseLength to 2048 by default, this will effect the default display of the ResponseLengthButtonGroup below.
    // It must match a valid value of one of the buttons in the ResponseLengthButtonGroup.tsx file. 
    // If you update the default value here, you must also update the default value in the onResponseLengthChange method.
    const [responseLength, setResponseLength] = useState<number>(2048);

    // Setting responseTemp to 0.6 by default, this will effect the default display of the ResponseTempButtonGroup below.
    // It must match a valid value of one of the buttons in the ResponseTempButtonGroup.tsx file.
    // If you update the default value here, you must also update the default value in the onResponseTempChange method.
    const [responseTemp, setResponseTemp] = useState<number>(0.6);

    const [activeChatMode, setChatMode] = useState<ChatMode>(ChatMode.WorkOnly);
    const [defaultApproach, setDefaultApproach] = useState<number>(Approaches.ReadRetrieveRead);
    const [activeApproach, setActiveApproach] = useState<number>(Approaches.ReadRetrieveRead);
    const [featureFlags, setFeatureFlags] = useState<GetFeatureFlagsResponse | undefined>(undefined);

    const lastQuestionRef = useRef<string>("");
    const lastQuestionWorkCitationRef = useRef<{ [key: string]: { citation: string; source_path: string; page_number: string } }>({});
    const lastQuestionWebCitiationRef = useRef<{ [key: string]: { citation: string; source_path: string; page_number: string } }>({});
    const lastQuestionThoughtChainRef = useRef<{ [key: string]: string }>({});
    const chatMessageStreamEnd = useRef<HTMLDivElement | null>(null);

    const [isLoading, setIsLoading] = useState<boolean>(false);
    const [error, setError] = useState<unknown>();

    const [activeCitation, setActiveCitation] = useState<string>();
    const [activeCitationSourceFile, setActiveCitationSourceFile] = useState<string>();
    const [activeCitationSourceFilePageNumber, setActiveCitationSourceFilePageNumber] = useState<string>();
    const [activeAnalysisPanelTab, setActiveAnalysisPanelTab] = useState<AnalysisPanelTabs | undefined>(undefined);
    const [selectedFolders, setSelectedFolders] = useState<string[]>([]);
    const [selectedTags, setSelectedTags] = useState<ITag[]>([]);

    const [selectedAnswer, setSelectedAnswer] = useState<number>(0);
    const [answers, setAnswers] = useState<[user: string, response: ChatResponse][]>([]);
    const [answerStream, setAnswerStream] = useState<ReadableStream | undefined>(undefined);

    async function fetchFeatureFlags() {
        try {
            const fetchedFeatureFlags = await getFeatureFlags();
            setFeatureFlags(fetchedFeatureFlags);
        } catch (error) {
            // Handle the error here
            console.log(error);
        }
    }

    const makeApiRequest = async (question: string, approach: Approaches, 
                                work_citation_lookup: { [key: string]: { citation: string; source_path: string; page_number: string } },
                                web_citation_lookup: { [key: string]: { citation: string; source_path: string; page_number: string } },
                                thought_chain: { [key: string]: string}) => {
        lastQuestionRef.current = question;
        lastQuestionWorkCitationRef.current = work_citation_lookup;
        lastQuestionWebCitiationRef.current = web_citation_lookup;
        lastQuestionThoughtChainRef.current = thought_chain;
        setActiveApproach(approach);

        error && setError(undefined);
        setIsLoading(true);
        setActiveCitation(undefined);
        setActiveAnalysisPanelTab(undefined);

        try {
            const history: ChatTurn[] = answers.map(a => ({ user: a[0], bot: a[1].answer }));
            const request: ChatRequest = {
                history: [...history, { user: question, bot: undefined }],
                approach: approach,
                overrides: {
                    promptTemplate: undefined,
                    excludeCategory: undefined,
                    top: retrieveCount,
                    semanticRanker: true,
                    semanticCaptions: false,
                    suggestFollowupQuestions: useSuggestFollowupQuestions,
                    userPersona: userPersona,
                    systemPersona: systemPersona,
                    aiPersona: "",
                    responseLength: responseLength,
                    responseTemp: responseTemp,
                    selectedFolders: selectedFolders.includes("selectAll") ? "All" : selectedFolders.length == 0 ? "All" : selectedFolders.join(","),
                    selectedTags: selectedTags.map(tag => tag.name).join(",")
                },
                citation_lookup: approach == Approaches.CompareWebWithWork ? web_citation_lookup : approach == Approaches.CompareWorkWithWeb ? work_citation_lookup : {},
                thought_chain: thought_chain
            };
            const result = await chatApi(request);
            if (!result.body) {
                throw Error("No response body");
            }

            const temp: ChatResponse = {
                answer: "",
                thoughts: "",
                data_points: [],
                approach: approach,
                thought_chain: {
                    "work_response": "",
                    "web_response": ""
                },
                work_citation_lookup: {},
                web_citation_lookup: {}
            };

            setAnswers([...answers, [question, temp]]);
            setAnswerStream(result.body);
        } catch (e) {
            setError(e);
        } finally {
            setIsLoading(false);
        }
    };

    const clearChat = () => {
        lastQuestionRef.current = "";
        lastQuestionWorkCitationRef.current = {};
        lastQuestionWebCitiationRef.current = {};
        lastQuestionThoughtChainRef.current = {};
        error && setError(undefined);
        setActiveCitation(undefined);
        setActiveAnalysisPanelTab(undefined);
        setAnswers([]);
    };

    const onResponseLengthChange = (_ev: any) => {
        for (let node of _ev.target.parentNode.childNodes) {
            if (node.value == _ev.target.value) {
                switch (node.value) {
                    case "1024":
                        node.className = `${rlbgstyles.buttonleftactive}`;
                        break;
                    case "2048":
                        node.className = `${rlbgstyles.buttonmiddleactive}`;
                        break;
                    case "3072":
                        node.className = `${rlbgstyles.buttonrightactive}`;
                        break;
                    default:
                        //do nothing
                        break;
                }
            }
            else {
                switch (node.value) {
                    case "1024":
                        node.className = `${rlbgstyles.buttonleft}`;
                        break;
                    case "2048":
                        node.className = `${rlbgstyles.buttonmiddle}`;
                        break;
                    case "3072":
                        node.className = `${rlbgstyles.buttonright}`;
                        break;
                    default:
                        //do nothing
                        break;
                }
            }
        }
        // the or value here needs to match the default value assigned to responseLength above.
        setResponseLength(_ev.target.value as number || 2048)
    };

    const onResponseTempChange = (_ev: any) => {
        for (let node of _ev.target.parentNode.childNodes) {
            if (node.value == _ev.target.value) {
                switch (node.value) {
                    case "1.0":
                        node.className = `${rtbgstyles.buttonleftactive}`;
                        break;
                    case "0.6":
                        node.className = `${rtbgstyles.buttonmiddleactive}`;
                        break;
                    case "0":
                        node.className = `${rtbgstyles.buttonrightactive}`;
                        break;
                    default:
                        //do nothing
                        break;
                }
            }
            else {
                switch (node.value) {
                    case "1.0":
                        node.className = `${rtbgstyles.buttonleft}`;
                        break;
                    case "0.6":
                        node.className = `${rtbgstyles.buttonmiddle}`;
                        break;
                    case "0":
                        node.className = `${rtbgstyles.buttonright}`;
                        break;
                    default:
                        //do nothing
                        break;
                }
            }
        }
        // the or value here needs to match the default value assigned to responseLength above.
        setResponseTemp(_ev.target.value as number || 0.6)
    };

    const onChatModeChange = (_ev: any) => {
        const chatMode = _ev.target.value as ChatMode || ChatMode.WorkOnly;
        setChatMode(chatMode);
        if (chatMode == ChatMode.WorkOnly)
                setDefaultApproach(Approaches.ReadRetrieveRead);
                setActiveApproach(Approaches.ReadRetrieveRead);
        if (chatMode == ChatMode.WorkPlusWeb)
            if (defaultApproach == Approaches.GPTDirect) 
                setDefaultApproach(Approaches.ReadRetrieveRead)
                setActiveApproach(Approaches.ReadRetrieveRead);
        if (chatMode == ChatMode.Ungrounded)
            setDefaultApproach(Approaches.GPTDirect)
            setActiveApproach(Approaches.GPTDirect);
        clearChat();
    }

    const handleToggle = () => {
        defaultApproach == Approaches.ReadRetrieveRead ? setDefaultApproach(Approaches.ChatWebRetrieveRead) : setDefaultApproach(Approaches.ReadRetrieveRead);
    }

    useEffect(() => {fetchFeatureFlags()}, []);
    useEffect(() => chatMessageStreamEnd.current?.scrollIntoView({ behavior: "smooth" }), [isLoading]);

    const onRetrieveCountChange = (_ev?: React.SyntheticEvent<HTMLElement, Event>, newValue?: string) => {
        setRetrieveCount(parseInt(newValue || "5"));
    };

    const onUserPersonaChange = (_ev?: React.FormEvent<HTMLInputElement | HTMLTextAreaElement>, newValue?: string) => {
        setUserPersona(newValue || "");
    }

    const onSystemPersonaChange = (_ev?: React.FormEvent<HTMLInputElement | HTMLTextAreaElement>, newValue?: string) => {
        setSystemPersona(newValue || "");
    }

    const onUseSuggestFollowupQuestionsChange = (_ev?: React.FormEvent<HTMLElement | HTMLInputElement>, checked?: boolean) => {
        setUseSuggestFollowupQuestions(!!checked);
    };

    const onExampleClicked = (example: string) => {
        makeApiRequest(example, defaultApproach, {}, {}, {});
    };

    const onShowCitation = (citation: string, citationSourceFile: string, citationSourceFilePageNumber: string, index: number) => {
        if (activeCitation === citation && activeAnalysisPanelTab === AnalysisPanelTabs.CitationTab && selectedAnswer === index) {
            setActiveAnalysisPanelTab(undefined);
        } else {
            setActiveCitation(citation);
            setActiveCitationSourceFile(citationSourceFile);
            setActiveCitationSourceFilePageNumber(citationSourceFilePageNumber);
            setActiveAnalysisPanelTab(AnalysisPanelTabs.CitationTab);
        }

        setSelectedAnswer(index);
    };

    const onToggleTab = (tab: AnalysisPanelTabs, index: number) => {
        if (activeAnalysisPanelTab === tab && selectedAnswer === index) {
            setActiveAnalysisPanelTab(undefined);
        } else {
            setActiveAnalysisPanelTab(tab);
        }

        setSelectedAnswer(index);
    };

    const onSelectedKeyChanged = (selectedFolders: string[]) => {
        setSelectedFolders(selectedFolders)
    };

    const onSelectedTagsChange = (selectedTags: ITag[]) => {
        setSelectedTags(selectedTags)
    }

    useEffect(() => {
        // Hide Scrollbar for this page
        document.body.classList.add('chat-overflow-hidden-body');
        // Do not apply to other pages
        return () => {
            document.body.classList.remove('chat-overflow-hidden-body');
        };
    }, []);

    const updateAnswerAtIndex = (index: number, response: ChatResponse) => {
        setAnswers(currentAnswers => {
            const updatedAnswers = [...currentAnswers];
            updatedAnswers[index] = [updatedAnswers[index][0], response];
            return updatedAnswers;
        });
    }

    const removeAnswerAtIndex = (index: number) => {
        const newItems = answers.filter((item, idx) => idx !== index);
        setAnswers(newItems);
    }

    return (
        <div className={styles.container}>
            <div className={styles.subHeader}>
                <ChatModeButtonGroup className="" defaultValue={activeChatMode} onClick={onChatModeChange} featureFlags={featureFlags} /> 
                <div className={styles.commandsContainer}>
                    <ClearChatButton className={styles.commandButton} onClick={clearChat} disabled={!lastQuestionRef.current || isLoading} />
                    <SettingsButton className={styles.commandButton} onClick={() => setIsConfigPanelOpen(!isConfigPanelOpen)} />
                    <InfoButton className={styles.commandButton} onClick={() => setIsInfoPanelOpen(!isInfoPanelOpen)} />
                </div>
            </div>
            <div className={styles.chatRoot}>
                <div className={styles.chatContainer}>
                    {!lastQuestionRef.current ? (
                        <div className={styles.chatEmptyState}>
                            {activeChatMode == ChatMode.WorkOnly ? 
                                <div>
                                    <div className={styles.chatEmptyStateHeader}> 
                                        <BuildingMultipleFilled fontSize={"100px"} primaryFill={"rgba(27, 74, 239, 1)"} aria-hidden="true" aria-label="Chat with your Work Data logo" />
                                        </div>
                                    <h1 className={styles.chatEmptyStateTitle}>Chat with your work data</h1>
                                </div>
                            : activeChatMode == ChatMode.WorkPlusWeb ?
                                <div>
                                    <div className={styles.chatEmptyStateHeader}> 
                                        <BuildingMultipleFilled fontSize={"80px"} primaryFill={"rgba(27, 74, 239, 1)"} aria-hidden="true" aria-label="Chat with your Work and Web Data logo" /><AddFilled fontSize={"50px"} primaryFill={"rgba(0, 0, 0, 0.7)"} aria-hidden="true" aria-label=""/><GlobeFilled fontSize={"80px"} primaryFill={"rgba(24, 141, 69, 1)"} aria-hidden="true" aria-label="" />
                                    </div>
                                    <h1 className={styles.chatEmptyStateTitle}>Chat with your work and web data</h1>
                                </div>
                            : //else Ungrounded
                                <div>
                                    <div className={styles.chatEmptyStateHeader}> 
                                        <ChatSparkleFilled fontSize={"80px"} primaryFill={"rgba(0, 0, 0, 0.35)"} aria-hidden="true" aria-label="Chat logo" />
                                    </div>
                                    <h1 className={styles.chatEmptyStateTitle}>Chat directly with a LLM</h1>
                                </div>
                            }
                            <span className={styles.chatEmptyObjectives}>
                                <i>Information Assistant uses AI. Check for mistakes.   </i><a href="https://github.com/microsoft/PubSec-Info-Assistant/blob/main/docs/transparency.md" target="_blank" rel="noopener noreferrer">Transparency Note</a>
                            </span>
                            {activeChatMode != ChatMode.Ungrounded &&
                                <div>
                                    <h2 className={styles.chatEmptyStateSubtitle}>Ask anything or try an example</h2>
                                    <ExampleList onExampleClicked={onExampleClicked} />
                                </div>
                            }
                        </div>
                    ) : (
                        <div className={styles.chatMessageStream}>
                            {answers.map((answer, index) => (
                                <div key={index}>
                                    <UserChatMessage
                                        message={answer[0]}
                                        approach={answer[1].approach}
                                    />
                                    <div className={styles.chatMessageGpt}>
                                        <Answer
                                            key={index}
                                            answer={answer[1]}
                                            answerStream={answerStream}
                                            setError={(error) => {setError(error); removeAnswerAtIndex(index); }}
                                            setAnswer={(response) => updateAnswerAtIndex(index, response)}
                                            isSelected={selectedAnswer === index && activeAnalysisPanelTab !== undefined}
                                            onCitationClicked={(c, s, p) => onShowCitation(c, s, p, index)}
                                            onThoughtProcessClicked={() => onToggleTab(AnalysisPanelTabs.ThoughtProcessTab, index)}
                                            onSupportingContentClicked={() => onToggleTab(AnalysisPanelTabs.SupportingContentTab, index)}
                                            onFollowupQuestionClicked={q => makeApiRequest(q, answer[1].approach, answer[1].work_citation_lookup, answer[1].web_citation_lookup, answer[1].thought_chain)}
                                            showFollowupQuestions={useSuggestFollowupQuestions && answers.length - 1 === index}
                                            onAdjustClick={() => setIsConfigPanelOpen(!isConfigPanelOpen)}
                                            onRegenerateClick={() => makeApiRequest(answers[index][0], answer[1].approach, answer[1].work_citation_lookup, answer[1].web_citation_lookup, answer[1].thought_chain)}
                                            onWebSearchClicked={() => makeApiRequest(answers[index][0], Approaches.ChatWebRetrieveRead, answer[1].work_citation_lookup, answer[1].web_citation_lookup, answer[1].thought_chain)}
                                            onWebCompareClicked={() => makeApiRequest(answers[index][0], Approaches.CompareWorkWithWeb, answer[1].work_citation_lookup, answer[1].web_citation_lookup, answer[1].thought_chain)}
                                            onRagCompareClicked={() => makeApiRequest(answers[index][0], Approaches.CompareWebWithWork, answer[1].work_citation_lookup, answer[1].web_citation_lookup, answer[1].thought_chain)}
                                            onRagSearchClicked={() => makeApiRequest(answers[index][0], Approaches.ReadRetrieveRead, answer[1].work_citation_lookup, answer[1].web_citation_lookup, answer[1].thought_chain)}
                                            chatMode={activeChatMode}
                                        />
                                    </div>
                                </div>
                            ))}
                            {error ? (
                                <>
                                    <UserChatMessage message={lastQuestionRef.current} approach={activeApproach}/>
                                    <div className={styles.chatMessageGptMinWidth}>
                                        <AnswerError error={error.toString()} onRetry={() => makeApiRequest(lastQuestionRef.current, activeApproach, lastQuestionWorkCitationRef.current, lastQuestionWebCitiationRef.current, lastQuestionThoughtChainRef.current)} />
                                    </div>
                                </>
                            ) : null}
                            <div ref={chatMessageStreamEnd} />
                        </div>
                    )}
                    
                    <div className={styles.chatInput}>
                        {activeChatMode == ChatMode.WorkPlusWeb && (
                            <div className={styles.chatInputWarningMessage}> 
                                {defaultApproach == Approaches.ReadRetrieveRead && 
                                    <div>Questions will be answered by default from Work <BuildingMultipleFilled fontSize={"20px"} primaryFill={"rgba(27, 74, 239, 1)"} aria-hidden="true" aria-label="Work Data" /></div>}
                                {defaultApproach == Approaches.ChatWebRetrieveRead && 
                                    <div>Questions will be answered by default from Web <GlobeFilled fontSize={"20px"} primaryFill={"rgba(24, 141, 69, 1)"} aria-hidden="true" aria-label="Web Data" /></div>
                                }
                            </div> 
                        )}
                        <QuestionInput
                            clearOnSend
                            placeholder="Type a new question (e.g. Who are Microsoft's top executives, provided as a table?)"
                            disabled={isLoading}
                            onSend={question => makeApiRequest(question, defaultApproach, {}, {}, {})}
                            onAdjustClick={() => setIsConfigPanelOpen(!isConfigPanelOpen)}
                            onInfoClick={() => setIsInfoPanelOpen(!isInfoPanelOpen)}
                            showClearChat={true}
                            onClearClick={clearChat}
                            onRegenerateClick={() => makeApiRequest(lastQuestionRef.current, defaultApproach, {}, {}, {})}
                        />
                    </div>
                </div>

                {answers.length > 0 && activeAnalysisPanelTab && (
                    <AnalysisPanel
                        className={styles.chatAnalysisPanel}
                        activeCitation={activeCitation}
                        sourceFile={activeCitationSourceFile}
                        pageNumber={activeCitationSourceFilePageNumber}
                        onActiveTabChanged={x => onToggleTab(x, selectedAnswer)}
                        citationHeight="760px"
                        answer={answers[selectedAnswer][1]}
                        activeTab={activeAnalysisPanelTab}
                    />
                )}

                <Panel
                    headerText="Configure answer generation"
                    isOpen={isConfigPanelOpen}
                    isBlocking={false}
                    onDismiss={() => setIsConfigPanelOpen(false)}
                    closeButtonAriaLabel="Close"
                    onRenderFooterContent={() => <DefaultButton onClick={() => setIsConfigPanelOpen(false)}>Close</DefaultButton>}
                    isFooterAtBottom={true}
                >
                    {activeChatMode == ChatMode.WorkPlusWeb &&
                        <div>
                            <Label>Use this datasource to answer Questions by default:</Label>
                            <div className={styles.defaultApproachSwitch}>
                                <div className={styles.defaultApproachWebOption} onClick={handleToggle}>Web</div>
                                <Switch onChange={handleToggle} checked={defaultApproach == Approaches.ReadRetrieveRead} uncheckedIcon={true} checkedIcon={true} onColor="#1B4AEF" offColor="#188d45"/>
                                <div className={styles.defaultApproachWorkOption} onClick={handleToggle}>Work</div>
                            </div>
                        </div>
                    }
                    {activeChatMode != ChatMode.Ungrounded &&
                        <SpinButton
                            className={styles.chatSettingsSeparator}
                            label="Retrieve this many documents from search:"
                            min={1}
                            max={50}
                            defaultValue={retrieveCount.toString()}
                            onChange={onRetrieveCountChange}
                        />
                    }
                    {activeChatMode != ChatMode.Ungrounded &&
                        <Checkbox
                            className={styles.chatSettingsSeparator}
                            checked={useSuggestFollowupQuestions}
                            label="Suggest follow-up questions"
                            onChange={onUseSuggestFollowupQuestionsChange}
                        />
                    }
                    <TextField className={styles.chatSettingsSeparator} defaultValue={userPersona} label="User Persona" onChange={onUserPersonaChange} />
                    <TextField className={styles.chatSettingsSeparator} defaultValue={systemPersona} label="System Persona" onChange={onSystemPersonaChange} />
                    <ResponseLengthButtonGroup className={styles.chatSettingsSeparator} onClick={onResponseLengthChange} defaultValue={responseLength} />
                    <ResponseTempButtonGroup className={styles.chatSettingsSeparator} onClick={onResponseTempChange} defaultValue={responseTemp} />
                    {activeChatMode != ChatMode.Ungrounded &&
                        <div>
                            <Separator className={styles.chatSettingsSeparator}>Filter Search Results by</Separator>
                            <FolderPicker allowFolderCreation={false} onSelectedKeyChange={onSelectedKeyChanged} preSelectedKeys={selectedFolders} />
                            <TagPickerInline allowNewTags={false} onSelectedTagsChange={onSelectedTagsChange} preSelectedTags={selectedTags} />
                        </div>
                    }
                </Panel>

                <Panel
                    headerText="Information"
                    isOpen={isInfoPanelOpen}
                    isBlocking={false}
                    onDismiss={() => setIsInfoPanelOpen(false)}
                    closeButtonAriaLabel="Close"
                    onRenderFooterContent={() => <DefaultButton onClick={() => setIsInfoPanelOpen(false)}>Close</DefaultButton>}
                    isFooterAtBottom={true}                >
                    <div className={styles.resultspanel}>
                        <InfoContent />
                    </div>
                </Panel>
            </div>
        </div>
    );
};

export default Chat;
