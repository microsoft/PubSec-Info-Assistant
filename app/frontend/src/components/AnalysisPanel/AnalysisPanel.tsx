// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

import { useEffect, useState } from "react";
import { IPivotItemProps, IRefObject, ITooltipHost, Pivot, PivotItem, Text, TooltipHost} from "@fluentui/react";
import { Label } from '@fluentui/react/lib/Label';
import { Separator } from '@fluentui/react/lib/Separator';
import DOMPurify from "dompurify";
import ReactMarkdown from 'react-markdown';

import styles from "./AnalysisPanel.module.css";

import { SupportingContent } from "../SupportingContent";
import { ChatResponse, ActiveCitation, getCitationObj, fetchCitationFile, FetchCitationFileResponse } from "../../api";
import { AnalysisPanelTabs } from "./AnalysisPanelTabs";
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
        <Pivot
            className={className}
            selectedKey={activeTab}
            onLinkClick={pivotItem => pivotItem && onActiveTabChanged(pivotItem.props.itemKey! as AnalysisPanelTabs)}
        >
            <PivotItem
                itemKey={AnalysisPanelTabs.ThoughtProcessTab}
                headerText="Thought process"
                headerButtonProps={isDisabledThoughtProcessTab ? { disabled: true, style: pivotItemDisabledStyle } : undefined}
                
            >
                <div className={styles.thoughtProcess} dangerouslySetInnerHTML={{ __html: sanitizedThoughts }}></div>
            </PivotItem>
            
            <PivotItem
                itemKey={AnalysisPanelTabs.SupportingContentTab}
                headerText="Supporting content"
                
                headerButtonProps={{
                    disabled: isDisabledSupportingContentTab,
                    style: isDisabledSupportingContentTab ?  pivotItemDisabledStyle : undefined,
                }}
                onRenderItemLink = {onRenderItemLink("Supporting content is unavailable.", tooltipRef2, isDisabledSupportingContentTab)}
            >
                <SupportingContent supportingContent={answer.data_points} />
            </PivotItem>
            
            
            <PivotItem
                itemKey={AnalysisPanelTabs.CitationTab}
                
                headerText="Citation"
                headerButtonProps={{
                    disabled: isDisabledCitationTab,
                    style: isDisabledCitationTab ?  pivotItemDisabledStyle : undefined,
                }}
                onRenderItemLink = {onRenderItemLink("No active citation selected. Please select a citation from the citations list on the left.", tooltipRef3, isDisabledCitationTab)}
            > 
            
                <Pivot className={className} selectedKey={innerPivotTab} onLinkClick={(item) => {
                    if (item) {
                        setInnerPivotTab(item.props.itemKey!);
                    } else {
                        // Handle the case where item is undefined
                        console.warn('Item is undefined');
                    }
                }}>
                    <PivotItem itemKey="indexedFile" headerText="Document Section">
                        {activeCitationObj === undefined ? (
                            <Text>Loading...</Text>
                        ) : 
                        (
                            <div>
                                <Separator>Metadata</Separator>
                                <Label>File Name</Label><Text>{activeCitationObj.file_name}</Text>
                                <Label>File URI</Label><Text>{activeCitationObj.file_uri}</Text>
                                <Label>Title</Label><Text>{activeCitationObj.title}</Text>
                                <Label>Section</Label><Text>{activeCitationObj.section}</Text>
                                <Label>Page Number(s)</Label><Text>{activeCitationObj.pages?.join(",")}</Text>
                                <Label>Token Count</Label><Text>{activeCitationObj.token_count}</Text>
                                <Separator>Content</Separator>
                                <Label>Content</Label><Text>{activeCitationObj.content}</Text>
                            </div>
                        )}
                    </PivotItem>
                    <PivotItem itemKey="rawFile" headerText="Document">
                        {getCitationURL() === '' ?  (
                            <Text>Loading...</Text>
                        ) : ["docx", "xlsx", "pptx"].includes(sourceFileExt) ? (
                            // Treat other Office formats like "xlsx" for the Office Online Viewer
                            <iframe title="Source File" src={'https://view.officeapps.live.com/op/view.aspx?src=' + encodeURIComponent(getCitationURL()) + "&action=embedview&wdStartOn=" + (pageNumber ?? '')} width="100%" height={citationHeight} />
                        ) : sourceFileExt === "pdf" ? (
                            // Use object tag for PDFs because iframe does not support page numbers
                            <object data={getCitationURL() + "#page=" + pageNumber} type="application/pdf" width="100%" height={citationHeight} />
                        ) : sourceFileExt === "md" ? (
                            // Render Markdown content using react-markdown
                            <ReactMarkdown>{markdownContent}</ReactMarkdown>
                        ) : ["json", "txt", "xml"].includes(sourceFileExt) ? (
                            // Render plain text content
                            <pre>{plainTextContent}</pre>
                        ) : (
                            // Default to iframe for other file types
                            <iframe title="Source File" src={getCitationURL()} width="100%" height={citationHeight} />
                        )}
                    </PivotItem>
                </Pivot>
            </PivotItem>
            
        </Pivot>
    );
};