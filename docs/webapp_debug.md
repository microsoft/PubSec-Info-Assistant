# Debugging the Information Assistant Web App in VS Code

If you wish to debug the user interface, or web app that as part of this accelerator, you can do this locally in VS Code and step through the logic. 

The app consists of two layers, namely the frontend user interface components and the backend logic components. As a user interacts with the user interface, they are engaging with the frontend code, and control is passed to the back end code as needed, for example to make calls to the Azure OpenAI service.

To debug the webapp, both frontend and backend, first set breakpoints in your code under the frontend and/or backend. Select the 'Run & Debug' tab from the sidebar in VS Code. Select `Python: WebApp backend` from the dropdown and hit run. This will initiate local debugging of the backend code.

Next verify you have a virtual environment created, which should be seen as a folder called .venv under the root of your workspace. If this doesn't exists you can create one by following these steps:

1. Opening the command palette (Ctrl+Shift+P)
1. Select the command Python: Create Environment
1. Next select Venv
1. Now select the latest version of Python from the list
1. Finally enter check marks next to all requirements.txt files listed and hit OK

This will initiate frontend running and debugging. A browser will open and show the web app running under localhost:5000. Next proceed to interact with the web app, by asking a question. In the VS Code interface, your code will hit the breakpoints, frontend or backend, and you will be able to view variable, trace logic etc. You can switch between the two running debuggers by selecting frontend or backend  (flask or vite) from the debug dropdown.

Now initiate debugging of the front end code by selecting 'Frontend: watch' and then hitting run
![backend debugging](/docs/images/frontend-watch.png)

Finally hit Vite: Debug
![backend debugging](/docs/images/vite-debug.png)

A browser will open and show the web app running under localhost:5000. Next proceed to interact with the web app, by asking a question. In the VS Code interface, you code will hit the breakpoints, frontend or backend, and you will be able to view variable, trace logic etc. You can switch between the two running debuggers by selecting frontend or backend  (flask or vite) from the debug dropdown.

## Known Issues

### Slow response

In testing we have found that interacting with the webapp through the browser is very slow after initiating debugging. We have found double clicks on buttons seems to trigger actions. After a few minutes, performance improves to an acceptable level.
