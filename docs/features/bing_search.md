# Bing Enhanced Search and Comparison

## Overview

This provides users with more comprehensive information and the ability to compare responses from Info Assistant with external Bing search results.

### New UI Buttons

#### Bing Search

The "Bing Search" button allows users to perform a Bing search based on their current conversation context. The retrieved results are then processed by the LLM, enriching the response with URL citations for a more informative answer.

#### Bing Compare

The "Bing Compare" button takes the grounded LLM response and performs a second Bing search. Instead of returning the Bing search LLM response directly, it compares the citations from both the grounded LLM response and the new Bing search, enhancing the grounded response with additional citations and comparative analysis.

#### Switch to Web Workspace

A new button in the subtitle bar labeled "Switch to Web" has been added. When clicked, it clears the chat history and changes the button label to "Switch to Work." This feature allows users to seamlessly switch between two workspaces:

- Work Workspace: Prompts in this workspace are directed to the grounded LLM with access to the "Bing Search" and "Bing Compare" buttons.
- Web Workspace: Prompts in this workspace behave as if the "Search Bing" button on a grounded response was pressed. Additionally, a "Compare Data" button appears on responses, facilitating a comparison between Bing search results and grounded LLM responses.

## Usage Instructions

### Bing Search Button:

1. Click the "Bing Search" button to perform a Bing search based on the current conversation context.
2. Review the response enriched with URL citations.

### Bing Compare Button:

1. Click the "Bing Compare" button to compare the data from a grounded LLM response with a new Bing search.
2. Explore the enhanced response that provides citations from it's externally gathered comparative data.

### Web Workspace (Search Bing):

- In the Web workspace, prompts behave as if the "Search Bing" button on a grounded response was pressed.
- Utilize the "Compare Data" button to compare Bing search results with grounded LLM responses.

## Notes

- This feature offers users a seamless transition between grounded and web-based information, providing a more versatile and comprehensive experience.
- Users can leverage the "Compare Data" button to validate information across different sources.
