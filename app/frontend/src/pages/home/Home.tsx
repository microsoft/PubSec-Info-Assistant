// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

import { useState } from 'react';
import { Pivot,
    PivotItem } from "@fluentui/react";

import styles from "./Home.module.css";

export interface IButtonExampleProps {
    // These are set based on the toggles shown above the examples (not needed in real code)
    disabled?: boolean;
    checked?: boolean;
  }

const Home = () => {
        return (
        <div className={styles.contentArea} >
            <p>This industry accelerator showcases integration between Azure and OpenAI's large language models. It leverages Azure AI Search for data retrieval and ChatGPT-style Q&A interactions. Using the Retrieval Augmented Generation (RAG) design pattern with Azure Open AI's GPT models, it provides a natural language interaction to discover relevant responses to user queries. Azure AI Search simplifies data ingestion, transformation, indexing, and multilingual translation.</p>
            <p>The accelerator adapts prompts based on the model type for enhanced performance. Users can customize settings like temperature and persona for personalized AI interactions. It offers features like explainable thought processes, referenceable citations, and direct content for verification.</p>
            <p>Please <a href='https://aka.ms/InfoAssist/video' target='_blank'>see this video</a> for use cases that may be achievable with this accelerator.</p>
        </div>
    );
};
    
export default Home;