#!/usr/bin/env python3
"""
MACRA Food Classifier Training Script
INTEGRATED FROM: AI4Food-NutritionDB, Nutrition5k

Trains a CoreML image classification model for on-device food recognition.
Uses transfer learning on MobileNetV3 for fast inference on iPhone.

Requirements:
    pip install coremltools torch torchvision pillow tqdm

Usage:
    # 1. Download training images (organize as folder-per-class):
    #    dataset/
    #      apple/
    #        img1.jpg, img2.jpg, ...
    #      banana/
    #        img1.jpg, img2.jpg, ...
    #      ...
    #
    # 2. Run training:
    python3 train_food_classifier.py --data ./dataset --output FoodClassifier.mlmodel
    #
    # 3. Copy FoodClassifier.mlmodel to:
    #    macra-ios/MACRA/Resources/FoodClassifier.mlmodel
    #    Then add to Xcode project.

    # For quick start with Food-101 dataset:
    python3 train_food_classifier.py --food101 --output FoodClassifier.mlmodel
"""

import argparse
import os
import sys

def train_with_createml(data_path: str, output_path: str):
    """Train using Apple's Create ML (macOS only, simplest approach)."""
    print("=== Create ML Training ===")
    print(f"Data: {data_path}")
    print(f"Output: {output_path}")
    print()
    print("To train with Create ML:")
    print("1. Open Create ML app (comes with Xcode)")
    print("2. Create new Image Classifier project")
    print(f"3. Drag '{data_path}' as training data")
    print("4. Set max iterations to 25")
    print("5. Train and export as .mlmodel")
    print(f"6. Save to: {output_path}")
    print()
    print("Or use the Python pipeline below for more control.")

def train_with_pytorch(data_path: str, output_path: str, epochs: int = 10):
    """Train using PyTorch + coremltools conversion."""
    try:
        import torch
        import torchvision
        from torchvision import transforms, datasets, models
        from torch import nn, optim
        from torch.utils.data import DataLoader
        import coremltools as ct
        from tqdm import tqdm
    except ImportError as e:
        print(f"Missing dependency: {e}")
        print("Install: pip install coremltools torch torchvision pillow tqdm")
        sys.exit(1)

    print(f"=== PyTorch Training Pipeline ===")
    print(f"Data: {data_path}")
    print(f"Epochs: {epochs}")

    # Data transforms
    train_transform = transforms.Compose([
        transforms.RandomResizedCrop(224),
        transforms.RandomHorizontalFlip(),
        transforms.ColorJitter(brightness=0.2, contrast=0.2, saturation=0.2),
        transforms.ToTensor(),
        transforms.Normalize([0.485, 0.456, 0.406], [0.229, 0.224, 0.225])
    ])

    # Load dataset (folder-per-class structure)
    dataset = datasets.ImageFolder(data_path, transform=train_transform)
    class_names = dataset.classes
    num_classes = len(class_names)
    print(f"Found {num_classes} food classes, {len(dataset)} images")

    # Split train/val
    train_size = int(0.85 * len(dataset))
    val_size = len(dataset) - train_size
    train_set, val_set = torch.utils.data.random_split(dataset, [train_size, val_size])

    train_loader = DataLoader(train_set, batch_size=32, shuffle=True, num_workers=4)
    val_loader = DataLoader(val_set, batch_size=32, shuffle=False, num_workers=4)

    # MobileNetV3 — small, fast, good for mobile
    device = torch.device("mps" if torch.backends.mps.is_available() else "cpu")
    print(f"Device: {device}")

    model = models.mobilenet_v3_small(weights=models.MobileNet_V3_Small_Weights.DEFAULT)
    model.classifier[-1] = nn.Linear(model.classifier[-1].in_features, num_classes)
    model = model.to(device)

    criterion = nn.CrossEntropyLoss()
    optimizer = optim.AdamW(model.parameters(), lr=1e-3, weight_decay=1e-4)
    scheduler = optim.lr_scheduler.CosineAnnealingLR(optimizer, T_max=epochs)

    # Training loop
    best_acc = 0.0
    for epoch in range(epochs):
        model.train()
        running_loss = 0.0
        correct = 0
        total = 0

        for images, labels in tqdm(train_loader, desc=f"Epoch {epoch+1}/{epochs}"):
            images, labels = images.to(device), labels.to(device)
            optimizer.zero_grad()
            outputs = model(images)
            loss = criterion(outputs, labels)
            loss.backward()
            optimizer.step()

            running_loss += loss.item()
            _, predicted = outputs.max(1)
            total += labels.size(0)
            correct += predicted.eq(labels).sum().item()

        train_acc = 100.0 * correct / total
        scheduler.step()

        # Validation
        model.eval()
        val_correct = 0
        val_total = 0
        with torch.no_grad():
            for images, labels in val_loader:
                images, labels = images.to(device), labels.to(device)
                outputs = model(images)
                _, predicted = outputs.max(1)
                val_total += labels.size(0)
                val_correct += predicted.eq(labels).sum().item()

        val_acc = 100.0 * val_correct / val_total
        print(f"  Train Acc: {train_acc:.1f}% | Val Acc: {val_acc:.1f}% | Loss: {running_loss/len(train_loader):.4f}")

        if val_acc > best_acc:
            best_acc = val_acc
            torch.save(model.state_dict(), "best_model.pth")

    # Load best model and convert to CoreML
    print(f"\nBest validation accuracy: {best_acc:.1f}%")
    model.load_state_dict(torch.load("best_model.pth"))
    model.eval()
    model = model.to("cpu")

    # Trace model
    example_input = torch.randn(1, 3, 224, 224)
    traced = torch.jit.trace(model, example_input)

    # Convert to CoreML
    print("Converting to CoreML...")
    mlmodel = ct.convert(
        traced,
        inputs=[ct.ImageType(name="image", shape=(1, 3, 224, 224), scale=1/255.0,
                             bias=[-0.485/0.229, -0.456/0.224, -0.406/0.225])],
        classifier_config=ct.ClassifierConfig(class_names),
        minimum_deployment_target=ct.target.iOS17,
    )

    mlmodel.author = "MACRA"
    mlmodel.short_description = "Food classification model for macra app"
    mlmodel.save(output_path)
    print(f"Saved CoreML model to: {output_path}")
    print(f"Model size: {os.path.getsize(output_path) / 1024 / 1024:.1f} MB")

    # Cleanup
    os.remove("best_model.pth")

def download_food101(output_dir: str):
    """Download Food-101 dataset (101 food classes, ~5GB)."""
    try:
        from torchvision.datasets import Food101
        print("Downloading Food-101 dataset (~5GB)...")
        Food101(root=output_dir, split="train", download=True)
        Food101(root=output_dir, split="test", download=True)
        return os.path.join(output_dir, "food-101", "images")
    except Exception as e:
        print(f"Failed to download Food-101: {e}")
        sys.exit(1)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Train MACRA Food Classifier")
    parser.add_argument("--data", type=str, help="Path to training data (folder-per-class)")
    parser.add_argument("--food101", action="store_true", help="Download and use Food-101 dataset")
    parser.add_argument("--output", type=str, default="FoodClassifier.mlmodel", help="Output .mlmodel path")
    parser.add_argument("--epochs", type=int, default=10, help="Training epochs")
    parser.add_argument("--createml", action="store_true", help="Show Create ML instructions instead")
    args = parser.parse_args()

    if args.createml:
        train_with_createml(args.data or "./dataset", args.output)
    elif args.food101:
        data_path = download_food101("./food101_data")
        train_with_pytorch(data_path, args.output, args.epochs)
    elif args.data:
        train_with_pytorch(args.data, args.output, args.epochs)
    else:
        print("Usage:")
        print("  python3 train_food_classifier.py --food101 --output FoodClassifier.mlmodel")
        print("  python3 train_food_classifier.py --data ./my_food_images --output FoodClassifier.mlmodel")
        print("  python3 train_food_classifier.py --createml")
