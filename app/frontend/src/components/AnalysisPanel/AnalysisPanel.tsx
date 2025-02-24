// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

import { useEffect, useState } from "react";
import { IPivotItemProps, IRefObject, ITooltipHost, Pivot, PivotItem, Text, TooltipHost} from "@fluentui/react";
import { Label } from '@fluentui/react/lib/Label';
import { Separator } from '@fluentui/react/lib/Separator';
import DOMPurify from "dompurify";
import ReactMarkdown from 'react-markdown';
import {
    DrawerBody,
    DrawerHeader,
    DrawerHeaderTitle,
    Drawer,
    DrawerProps,
    Button,
    Radio,
    RadioGroup,
    DrawerFooter,
    makeStyles,
    shorthands,
    tokens,
    useId,
  } from "@fluentui/react-components";
import styles from "./AnalysisPanel.module.css";

import { SupportingContent } from "../SupportingContent";
import { ChatResponse, ActiveCitation, getCitationObj, fetchCitationFile, FetchCitationFileResponse } from "../../api";
import { AnalysisPanelTabs } from "./AnalysisPanelTabs";
import { ArrowDownload16Filled } from '@fluentui/react-icons';
import React from "react";

interface Props {
    className: string;
    activeTab: AnalysisPanelTabs;
    onActiveTabChanged: (tab: AnalysisPanelTabs) => void;
    activeCitation: string | undefined;
    sourceFile: string | undefined;
    pageNumber: string | undefined;
    citationHeight: string;
    answer: ChatResponse;
}

const pivotItemDisabledStyle: React.CSSProperties = {
    color: 'grey'
    
};



const downloadFile = (sourceFileUrl: string | undefined, sourceFile: string | undefined) => {
    if (sourceFileUrl) {
        const link = document.createElement('a');
        link.href = sourceFileUrl;
        link.download = sourceFile?.split('/').pop() || 'download';
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
    }
};

export const AnalysisPanel = ({ answer, activeTab, activeCitation, sourceFile, pageNumber, citationHeight, className, onActiveTabChanged }: Props) => {
    
    const [innerPivotTab, setInnerPivotTab] = useState<string>('indexedFile');
    const [activeCitationObj, setActiveCitationObj] = useState<ActiveCitation>();
    const [markdownContent, setMarkdownContent] = useState('');
    const [plainTextContent, setPlainTextContent] = useState('');
    const [sourceFileBlob, setSourceFileBlob] = useState<Blob>();
    const [sourceFileUrl, setSourceFileUrl] = useState<string>('');
    const [isFetchingSourceFileBlob, setIsFetchingSourceFileBlob] = useState(false);
    const isDisabledThoughtProcessTab: boolean = !answer.thoughts;
    const isDisabledSupportingContentTab: boolean = !answer.data_points?.length;
    const isDisabledCitationTab: boolean = !activeCitation;
    // the first split on ? separates the file from the sas token, then the second split on . separates the file extension
    const sourceFileExt: any = sourceFile?.split(".").pop();
    const sanitizedThoughts = DOMPurify.sanitize(answer.thoughts!);

    const tooltipRef2 = React.useRef<ITooltipHost>(null);
    const tooltipRef3 = React.useRef<ITooltipHost>(null);
    
    const onRenderItemLink = (content: string | JSX.Element | JSX.Element[] | undefined, tooltipRef: IRefObject<ITooltipHost> | undefined, shouldRender: boolean) => (properties: IPivotItemProps | undefined,
        nullableDefaultRenderer?: (props: IPivotItemProps) => JSX.Element | null) => {
            if (!properties || !nullableDefaultRenderer) {
                return null; // or handle the undefined case appropriately
            }
            return shouldRender ? (
                <TooltipHost content={content} componentRef={tooltipRef}>
                    {nullableDefaultRenderer(properties)}
                </TooltipHost>
            ) : (
                nullableDefaultRenderer(properties)
            );
    };
    
    let sourceFileBlobPromise: Promise<void> | null = null;
    async function fetchCitationSourceFile(): Promise<void> {
        if (sourceFile) {
            const results = await fetchCitationFile(sourceFile);
            setSourceFileBlob(results.file_blob);
            setSourceFileUrl(URL.createObjectURL(results.file_blob));
        }
    }

    function getCitationURL() {
        const fetchSourceFileBlob = async () => {
            if (sourceFileBlob === undefined) {
                if (!isFetchingSourceFileBlob) {
                    setIsFetchingSourceFileBlob(true);
                    if (sourceFileUrl !== undefined) {
                        sourceFileBlobPromise = fetchCitationSourceFile().finally(() => {
                            setIsFetchingSourceFileBlob(false);
                        });
                    } else {
                        console.error("sourceFileUrl is undefined");
                        setIsFetchingSourceFileBlob(false);
                    }
                }
                await sourceFileBlobPromise;
            }
        };
    
        if (sourceFileBlob !== undefined) {
            fetchSourceFileBlob();
            
        }
        return sourceFileUrl ?? '';
    }

async function fetchActiveCitationObj() {
    try {
        if (!activeCitation) {
            console.warn('Active citation is undefined');
            setActiveCitationObj(undefined);
            return;
        }
        const citationObj = await getCitationObj(activeCitation);
        setActiveCitationObj(citationObj);
        console.log(citationObj);
    } catch (error) {
        // Handle the error here
        console.log(error);
    }
}
const renderContent = () => {
    switch (activeTab) {
        case AnalysisPanelTabs.ThoughtProcessTab:
            return (
                <div className={styles.thoughtProcess} dangerouslySetInnerHTML={{ __html: sanitizedThoughts }}></div>
            );
        case AnalysisPanelTabs.SupportingContentTab:
            return <SupportingContent supportingContent={answer.data_points} />;
        case AnalysisPanelTabs.CitationTab:
            return (
                <div>
                    <button
                    className={`${styles.tabButton} ${innerPivotTab === 'indexedFile' ? styles.activeTab : ''}`} onClick={() => setInnerPivotTab('indexedFile')}>Document Section</button>
                    <button 
                    className={`${styles.tabButton} ${innerPivotTab === 'rawFile' ? styles.activeTab : ''}`}
                    onClick={() => setInnerPivotTab('rawFile')}>Document</button>
                    {innerPivotTab === 'indexedFile' && (
                        <div>
                            {activeCitationObj === undefined ? (
                                <Text>Loading...</Text>
                            ) : (
                                <div>
                                    <Separator>Metadata</Separator>
                                    <Label>File Name</Label><Text>{activeCitationObj.file_name}</Text>
                                    <Separator>Content</Separator>
                                    <Label>Content</Label><Text>{activeCitationObj.content}</Text>
                                </div>
                            )}
                        </div>
                    )}
                    {innerPivotTab === 'rawFile' && (
                        <div>
                            {getCitationURL() === '' ? (
                                <Text>Loading...</Text>
                            ) : ["docx", "xlsx", "pptx"].includes(sourceFileExt) ? (
                                <iframe title="Source File" src={'https://view.officeapps.live.com/op/view.aspx?src=' + encodeURIComponent(getCitationURL()) + "&action=embedview&wdStartOn=" + (pageNumber ?? '')} width="100%" height={citationHeight} />
                            ) : sourceFileExt === "pdf" ? (
                                <object data={getCitationURL() + "#page=" + pageNumber} type="application/pdf" width="100%" height={citationHeight} />
                            ) : sourceFileExt === "md" ? (
                                <ReactMarkdown>{markdownContent}</ReactMarkdown>
                            ) : ["json", "txt", "xml"].includes(sourceFileExt) ? (
                                <pre>{plainTextContent}</pre>
                            ) : (
                                <iframe title="Source File" src={getCitationURL()} width="100%" height={citationHeight} />
                            )}
                            <Button 
                                onClick={() => downloadFile(sourceFileUrl, sourceFile)} 
                                style={{ border: '2px solid black', marginBottom: '10px' }}
                            >
                                <ArrowDownload16Filled />Download
                            </Button>
                        </div>
                    )}
                </div>
            );
        default:
            return null;
    }
};

useEffect(() => {
    const fetchMarkdownContent = async () => {
        try {
            if (!sourceFile) {
                console.error('Source file is undefined');
                return;
            }
            const citationURL = getCitationURL();
            if (!citationURL) {
                throw new Error('Citation URL is undefined');
            }
            const response = await fetch(citationURL);
            const content = await response.text();
            setMarkdownContent(content);
        } catch (error) {
            console.error('Error fetching Markdown content:', error);
        }
    };

    fetchMarkdownContent();
}, [sourceFileBlob, sourceFileExt]);

useEffect(() => {
    const fetchPlainTextContent = async () => {
        try {
            if (!sourceFile) {
                console.error('Source file is undefined');
                return;
            }

            const citationURL = getCitationURL();
            if (!citationURL) {
                throw new Error('Citation URL is undefined');
            }
            const response = await fetch(citationURL);
            const content = await response.text();
            setPlainTextContent(content);
        } catch (error) {
            console.error('Error fetching plain text content:', error);
        }
    };

    if (["json", "txt", "xml"].includes(sourceFileExt)) {
        fetchPlainTextContent();
    }
}, [sourceFileBlob, sourceFileExt]);

useEffect(() => {
    if (activeCitation) {
        setInnerPivotTab('indexedFile');
    } else {
        console.warn('Active citation is undefined');
        setActiveCitationObj(undefined);
    }

    fetchActiveCitationObj();

    const fetchSourceFileBlob = async () => {
        if (!sourceFile) {
            console.error('Source file is undefined');
            return;
        }
        if (!isFetchingSourceFileBlob) {
            setIsFetchingSourceFileBlob(true);
            sourceFileBlobPromise = fetchCitationSourceFile().finally(() => {
                setIsFetchingSourceFileBlob(false);
            });
        }
        await sourceFileBlobPromise;
    };

    fetchSourceFileBlob();
}, [activeCitation]);
    return (
        <Drawer
            type="inline"
            open={true}
            // onDismiss={() => onActiveTabChanged(AnalysisPanelTabs.None)}
            className={className}
        >
            {/* <DrawerHeader>
                <DrawerTitle>Analysis Panel</DrawerTitle>
                <DrawerSubtitle>Select a tab to view details</DrawerSubtitle>
            </DrawerHeader> */}
            <DrawerBody>
            <div className={styles.tabContainer}>
                    <TooltipHost content={isDisabledThoughtProcessTab ? "Thought process is disabled" : "View thought process"}>
                        <button
                            className={`${styles.tabButton} ${activeTab === AnalysisPanelTabs.ThoughtProcessTab ? styles.activeTab : ''}`}
                            disabled={isDisabledThoughtProcessTab}
                            onClick={() => onActiveTabChanged(AnalysisPanelTabs.ThoughtProcessTab)}
                        >
                            Thought process
                        </button>
                    </TooltipHost>
                    <TooltipHost content={isDisabledSupportingContentTab ? "Supporting content is disabled" : "View supporting content"}>
                        <button
                            className={`${styles.tabButton} ${activeTab === AnalysisPanelTabs.SupportingContentTab ? styles.activeTab : ''}`}
                            disabled={isDisabledSupportingContentTab}
                            onClick={() => onActiveTabChanged(AnalysisPanelTabs.SupportingContentTab)}
                        >
                            Supporting content
                        </button>
                    </TooltipHost>
                    <TooltipHost content={isDisabledCitationTab ? "Citation is disabled" : "View citation"}>
                        <button
                            className={`${styles.tabButton} ${activeTab === AnalysisPanelTabs.CitationTab ? styles.activeTab : ''}`}
                            onClick={() => {
                                onActiveTabChanged(AnalysisPanelTabs.CitationTab);
                                setInnerPivotTab('rawFile');
                            }}
                            disabled={isDisabledCitationTab}
                        >
                            Citation
                        </button>
                    </TooltipHost>
                </div>
                {renderContent()}
            </DrawerBody>
            <DrawerFooter>
                <button onClick={() => onActiveTabChanged(AnalysisPanelTabs.None)}>Close</button>
            </DrawerFooter>
        </Drawer>
    );
};
