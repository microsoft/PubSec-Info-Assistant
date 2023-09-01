// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

import { useEffect, useState } from "react";
import { Pivot, PivotItem, Text } from "@fluentui/react";
import { Label } from '@fluentui/react/lib/Label';
import { Separator } from '@fluentui/react/lib/Separator';
import DOMPurify from "dompurify";

import styles from "./AnalysisPanel.module.css";

import { SupportingContent } from "../SupportingContent";
import { AskResponse, ActiveCitation, getCitationObj } from "../../api";
import { AnalysisPanelTabs } from "./AnalysisPanelTabs";

interface Props {
    className: string;
    activeTab: AnalysisPanelTabs;
    onActiveTabChanged: (tab: AnalysisPanelTabs) => void;
    activeCitation: string | undefined;
    sourceFile: string | undefined;
    pageNumber: string | undefined;
    citationHeight: string;
    answer: AskResponse;
}

const pivotItemDisabledStyle = { disabled: true, style: { color: "grey" } };

export const AnalysisPanel = ({ answer, activeTab, activeCitation, sourceFile, pageNumber, citationHeight, className, onActiveTabChanged }: Props) => {
    const [activeCitationObj, setActiveCitationObj] = useState<ActiveCitation>();

    const isDisabledThoughtProcessTab: boolean = !answer.thoughts;
    const isDisabledSupportingContentTab: boolean = !answer.data_points.length;
    const isDisabledCitationTab: boolean = !activeCitation;
    // the first split on ? separates the file from the sas token, then the second split on . separates the file extension
    const sourceFileExt: any = sourceFile?.split("?")[0].split(".").pop();
    const sanitizedThoughts = DOMPurify.sanitize(answer.thoughts!);

    async function fetchActiveCitationObj() {
        try {
            const citationObj = await getCitationObj(activeCitation as string);
            setActiveCitationObj(citationObj);
            console.log(citationObj);
        } catch (error) {
            // Handle the error here
            console.log(error);
        }
    }

    useEffect(() => {
        fetchActiveCitationObj();
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
                headerButtonProps={isDisabledThoughtProcessTab ? pivotItemDisabledStyle : undefined}
            >
                <div className={styles.thoughtProcess} dangerouslySetInnerHTML={{ __html: sanitizedThoughts }}></div>
            </PivotItem>
            <PivotItem
                itemKey={AnalysisPanelTabs.SupportingContentTab}
                headerText="Supporting content"
                headerButtonProps={isDisabledSupportingContentTab ? pivotItemDisabledStyle : undefined}
            >
                <SupportingContent supportingContent={answer.data_points} />
            </PivotItem>
            <PivotItem
                itemKey={AnalysisPanelTabs.CitationTab}
                headerText="Citation"
                headerButtonProps={isDisabledCitationTab ? pivotItemDisabledStyle : undefined}
            >
                <Pivot className={className}>
                    <PivotItem itemKey="indexedFile" headerText="Document Section">
                        { activeCitationObj === undefined ? (
                            <Text>Loading...</Text>
                        ) : (
                            <div>
                            <Separator>Metadata</Separator>
                            <Label>File Name</Label><span>{activeCitationObj.file_name}</span>
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
                        { sourceFileExt === "pdf" ? (
                            //use object tag for pdfs because iframe does not support page numbers
                            <object data={sourceFile + "#page=" + pageNumber} type="application/pdf" width="100%" height={citationHeight} />
                        ) : ( sourceFileExt === "docx" ? (
                            <iframe title="Source File" src={'https://view.officeapps.live.com/op/view.aspx?src='+encodeURIComponent(sourceFile as string)+"&action=embedview&wdStartOn="+pageNumber} width="100%" height={citationHeight} />
                        ) : (
                            <iframe title="Source File" src={sourceFile} width="100%" height={citationHeight} />
                        )) }
                    </PivotItem>
                </Pivot>
            </PivotItem>
        </Pivot>
    );
};
