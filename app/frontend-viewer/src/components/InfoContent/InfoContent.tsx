// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

import React, { useEffect, useState } from "react";
import { Text } from "@fluentui/react";
import { Label } from '@fluentui/react/lib/Label';
import { Separator } from '@fluentui/react/lib/Separator';
import { getInfoData, GetInfoResponse } from "../../api";

interface Props {
    className?: string;
}

export const InfoContent = ({ className }: Props) => {
    const [infoData, setInfoData] = useState<GetInfoResponse | null>(null);

    async function fetchInfoData() {
        console.log("InfoContent 1");
        try {
            const fetchedInfoData = await getInfoData();
            setInfoData(fetchedInfoData);
        } catch (error) {
            // Handle the error here
            console.log(error);
        }
    }

    useEffect(() => {
        fetchInfoData();
    }, []);

    return (
        <div>
            <Separator>Azure OpenAI</Separator>
            <Label>Instance</Label><Text>{infoData?.AZURE_OPENAI_SERVICE}</Text>
            <Label>GPT Deployment Name</Label><Text>{infoData?.AZURE_OPENAI_CHATGPT_DEPLOYMENT}</Text>
            <Label>GPT Model Name</Label><Text>{infoData?.AZURE_OPENAI_MODEL_NAME}</Text>
            <Label>GPT Model Version</Label><Text>{infoData?.AZURE_OPENAI_MODEL_VERSION}</Text>
            {infoData?.USE_AZURE_OPENAI_EMBEDDINGS ? (
            <div>
            <Label>Embeddings Deployment Name</Label><Text>{infoData?.EMBEDDINGS_DEPLOYMENT}</Text>
            <Label>Embeddings Model Name</Label><Text>{infoData?.EMBEDDINGS_MODEL_NAME}</Text>
            <Label>Embeddings Model Version</Label><Text>{infoData?.EMBEDDINGS_MODEL_VERSION}</Text>
            </div>
            ) : (
            <div>
            <Separator>Open Source Embeddings</Separator>
            <Label>Embeddings Model</Label><Text>{infoData?.EMBEDDINGS_DEPLOYMENT}</Text>
            </div>
            )}
            <Separator>Azure AI Search</Separator>
            <Label>Service Name</Label><Text>{infoData?.AZURE_SEARCH_SERVICE}</Text>
            <Label>Index Name</Label><Text>{infoData?.AZURE_SEARCH_INDEX}</Text>
            <Separator>System Configuration</Separator>
            <Label>System Language</Label><Text>{infoData?.TARGET_LANGUAGE}</Text>
        </div>
    );
};