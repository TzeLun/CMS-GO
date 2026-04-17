from openai import OpenAI
import json
from typing import Dict, Any
from .config import get_settings

settings = get_settings()


async def transcribe_audio(audio_file_path: str) -> Dict[str, Any]:
    """
    Transcribe audio using OpenAI Whisper API.
    Supports English and Mandarin with speaker diarization.
    """
    try:
        client = OpenAI(api_key=settings.openai_api_key)

        with open(audio_file_path, 'rb') as audio_file:
            # Use OpenAI Whisper API for transcription
            transcript = client.audio.transcriptions.create(
                model="whisper-1",
                file=audio_file,
                response_format="verbose_json",
                timestamp_granularities=["segment"]
            )

        # Extract transcription text
        transcription = transcript.text

        # Convert segments to dictionaries for serialization
        segments = None
        if hasattr(transcript, 'segments') and transcript.segments:
            segments = [
                {
                    "id": seg.id,
                    "start": seg.start,
                    "end": seg.end,
                    "text": seg.text,
                }
                for seg in transcript.segments
            ]

        # Note: OpenAI Whisper doesn't provide built-in speaker diarization
        # For production, consider using additional services like Pyannote or AssemblyAI
        # for speaker diarization

        return {
            "transcription": transcription,
            "language": transcript.language if hasattr(transcript, 'language') else None,
            "segments": segments,
        }
    except Exception as e:
        raise Exception(f"Transcription failed: {str(e)}")


async def extract_contact_info(transcription: str) -> Dict[str, Any]:
    """
    Extract contact information from transcription using OpenAI GPT.
    """
    try:
        client = OpenAI(api_key=settings.openai_api_key)

        prompt = f"""
You are an AI assistant specialized in extracting contact and business information from conversation transcripts.

Analyze the following conversation transcript and extract relevant information in JSON format.

Extract the following fields if available:
- company_name: The name of the client's company
- client_name: The name of the client/person
- business_model: Description of their business model
- business_operation: How they operate their business
- target_market: Their target market or audience
- looking_for: What they are looking for or seeking
- phone_number: Contact phone number
- email: Contact email address
- additional_notes: Any other relevant information

If a field is not mentioned or unclear, set it to null.

Transcript:
{transcription}

Respond with ONLY a valid JSON object, no additional text.
"""

        response = client.chat.completions.create(
            model="gpt-4",
            messages=[
                {"role": "system", "content": "You are a helpful assistant that extracts structured contact information from conversations. Always respond with valid JSON."},
                {"role": "user", "content": prompt}
            ],
            temperature=0.3,
            max_tokens=1000,
        )

        # Extract the response content
        content = response.choices[0].message.content.strip()

        # Parse JSON response
        try:
            # Remove markdown code blocks if present
            if content.startswith("```json"):
                content = content[7:]
            if content.startswith("```"):
                content = content[3:]
            if content.endswith("```"):
                content = content[:-3]
            content = content.strip()

            extracted_info = json.loads(content)
            return extracted_info
        except json.JSONDecodeError:
            # If JSON parsing fails, return empty dict
            return {
                "company_name": None,
                "client_name": None,
                "business_model": None,
                "business_operation": None,
                "target_market": None,
                "looking_for": None,
                "phone_number": None,
                "email": None,
                "additional_notes": content,
            }

    except Exception as e:
        raise Exception(f"Information extraction failed: {str(e)}")
