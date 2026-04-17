from fastapi import FastAPI, Depends, HTTPException, status, File, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from typing import List
import os
import shutil
from datetime import timedelta

from .database import engine, get_db, Base
from .models import User, Contact
from .schemas import (
    UserCreate, UserLogin, UserResponse, Token,
    ContactCreate, ContactUpdate, ContactResponse,
    TranscriptionResponse, ExtractionRequest, ExtractionResponse
)
from .auth import (
    verify_password, get_password_hash, create_access_token,
    get_current_user
)
from .ai_service import transcribe_audio, extract_contact_info
from .config import get_settings

settings = get_settings()

# Create database tables
Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="Contact Management System API",
    description="Enterprise-grade API for contact management with AI-powered transcription",
    version="1.0.0"
)

# CORS Configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify exact origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# Authentication Routes
@app.post("/api/auth/register", response_model=dict, status_code=status.HTTP_201_CREATED)
async def register(user_data: UserCreate, db: Session = Depends(get_db)):
    """Register a new user"""
    # Check if user exists
    existing_user = db.query(User).filter(User.email == user_data.email).first()
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email already registered"
        )

    # Create new user
    hashed_password = get_password_hash(user_data.password)
    new_user = User(
        email=user_data.email,
        name=user_data.name,
        hashed_password=hashed_password
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)

    # Create access token
    access_token = create_access_token(data={"sub": new_user.email})

    return {
        "user": UserResponse.model_validate(new_user),
        "token": access_token
    }


@app.post("/api/auth/login", response_model=dict)
async def login(user_data: UserLogin, db: Session = Depends(get_db)):
    """Login user"""
    user = db.query(User).filter(User.email == user_data.email).first()
    if not user or not verify_password(user_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password"
        )

    # Create access token
    access_token = create_access_token(data={"sub": user.email})

    return {
        "user": UserResponse.model_validate(user),
        "token": access_token
    }


# Contact Routes
@app.get("/api/contacts", response_model=List[ContactResponse])
async def get_contacts(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get all contacts for the current user"""
    contacts = db.query(Contact).filter(Contact.user_id == current_user.id).all()
    return contacts


@app.get("/api/contacts/{contact_id}", response_model=ContactResponse)
async def get_contact(
    contact_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get a specific contact"""
    contact = db.query(Contact).filter(
        Contact.id == contact_id,
        Contact.user_id == current_user.id
    ).first()

    if not contact:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Contact not found"
        )

    return contact


@app.post("/api/contacts", response_model=ContactResponse, status_code=status.HTTP_201_CREATED)
async def create_contact(
    contact_data: ContactCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Create a new contact"""
    new_contact = Contact(
        user_id=current_user.id,
        **contact_data.model_dump()
    )
    db.add(new_contact)
    db.commit()
    db.refresh(new_contact)
    return new_contact


@app.put("/api/contacts/{contact_id}", response_model=ContactResponse)
async def update_contact(
    contact_id: int,
    contact_data: ContactUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Update a contact"""
    contact = db.query(Contact).filter(
        Contact.id == contact_id,
        Contact.user_id == current_user.id
    ).first()

    if not contact:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Contact not found"
        )

    # Update fields
    for field, value in contact_data.model_dump(exclude_unset=True).items():
        setattr(contact, field, value)

    db.commit()
    db.refresh(contact)
    return contact


@app.delete("/api/contacts/{contact_id}", status_code=status.HTTP_200_OK)
async def delete_contact(
    contact_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Delete a contact"""
    contact = db.query(Contact).filter(
        Contact.id == contact_id,
        Contact.user_id == current_user.id
    ).first()

    if not contact:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Contact not found"
        )

    db.delete(contact)
    db.commit()
    return {"message": "Contact deleted successfully"}


# AI Routes
@app.post("/api/transcribe", response_model=TranscriptionResponse)
async def transcribe(
    audio: UploadFile = File(...),
    current_user: User = Depends(get_current_user)
):
    """Transcribe audio file using OpenAI Whisper"""
    # Save uploaded file temporarily to /tmp (Cloud Run compatible)
    upload_dir = "/tmp"
    os.makedirs(upload_dir, exist_ok=True)

    file_path = os.path.join(upload_dir, audio.filename)
    with open(file_path, "wb") as buffer:
        shutil.copyfileobj(audio.file, buffer)

    try:
        # Transcribe audio
        result = await transcribe_audio(file_path)
        return TranscriptionResponse(
            transcription=result["transcription"],
            speakers=result.get("segments")
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )
    finally:
        # Clean up temporary file
        if os.path.exists(file_path):
            os.remove(file_path)


@app.post("/api/extract", response_model=ExtractionResponse)
async def extract(
    request: ExtractionRequest,
    current_user: User = Depends(get_current_user)
):
    """Extract contact information from transcription using OpenAI GPT"""
    try:
        result = await extract_contact_info(request.transcription)
        return ExtractionResponse(**result)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )


@app.get("/")
async def root():
    """API root endpoint"""
    return {
        "message": "Contact Management System API",
        "version": "1.0.0",
        "docs": "/docs"
    }


@app.get("/health")
async def health():
    """Health check endpoint"""
    return {"status": "healthy"}
