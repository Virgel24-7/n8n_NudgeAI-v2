NudgeAI: Context-aware AI-powered Email Follow up Agent
N8N self-hosted through Docker desktop

Initialization:

1. Create variables.ps1.
2. Copy contents of variables.ps1.example and paste in variables.ps1.
3. Provide the new values.
4. Run toN8N.ps1
5. Run newly made container in docker desktop and setup account.
6. Once logged in, run toN8N.ps1 again.

---

NOTE: If you want to use Git to edit and sync workflows across devices, update useGit in variables.ps1 to true.
toGIT.ps1 pushes your workflow to current active Git, and toN8N pulls your workflow from Git and load it in n8n.
