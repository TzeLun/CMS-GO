from pydantic import BaseModel, EmailStr
from datetime import datetime
from typing import Optional, List, Any


class UserCreate(BaseModel):
    email: EmailStr
    name: str
    password: str


class UserLogin(BaseModel):
    email: EmailStr
    password: str


class UserResponse(BaseModel):
    id: int
    email: str
    name: str
    created_at: datetime

    class Config:
        from_attributes = True


class Token(BaseModel):
    access_token: str
    token_type: str


class TokenData(BaseModel):
    email: Optional[str] = None


class ContactBase(BaseModel):
    company_name: Optional[str] = None
    client_name: Optional[str] = None
    business_model: Optional[str] = None
    business_operation: Optional[str] = None
    target_market: Optional[str] = None
    looking_for: Optional[str] = None
    phone_number: Optional[str] = None
    email: Optional[str] = None
    additional_notes: Optional[str] = None
    audio_file_path: Optional[str] = None
    transcription: Optional[str] = None


class ContactCreate(ContactBase):
    pass


class ContactUpdate(ContactBase):
    pass


class ContactResponse(ContactBase):
    id: int
    user_id: int
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class TranscriptionRequest(BaseModel):
    audio_file: str


class TranscriptionResponse(BaseModel):
    transcription: str
    speakers: Optional[List[Any]] = None  # Whisper returns segments as a list


class ExtractionRequest(BaseModel):
    transcription: str


class ExtractionResponse(BaseModel):
    company_name: Optional[str] = None
    client_name: Optional[str] = None
    business_model: Optional[str] = None
    business_operation: Optional[str] = None
    target_market: Optional[str] = None
    looking_for: Optional[str] = None
    phone_number: Optional[str] = None
    email: Optional[str] = None
    additional_notes: Optional[str] = None
