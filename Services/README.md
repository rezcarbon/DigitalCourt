# Carbon API Integration

This folder contains the integration with the Carbon GenAI Agent API.

## Files:
- `BotWithKnowledgebaseService.swift`: Main service for bot interactions.
- `CarbonAPIConfig.swift`: Configuration for the Carbon API.
- `CarbonAPIModels.swift`: Data models for the Carbon API.
- `CarbonAPIService.swift`: Service client for communicating with the API.
- `KnowledgebaseService.swift`: Manages interactions with the knowledgebase.
- `openapi.json`: OpenAPI specification for the GenAI Agent API.

### Models

## Integration with Digital Court
The LLMManager has been updated to use the Carbon API for all AI interactions.
The SoulCapsule information is converted to system messages for the API.

## Configuration
To use this integration:
1. Update `CarbonAPIConfig.baseURL` with your Carbon API endpoint
2. Replace `CarbonAPIConfig.apiKey` with your actual API key