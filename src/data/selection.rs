use std::cmp::Ordering;

#[derive(Debug, Clone, Data, Eq)]
pub enum SelectableItem<T> {
    Selectable(T, SelectedState),
    Disabled(T),
    Subheading(T),
}

impl<T> SelectableItem<T> {
    pub fn select(&mut self) {
        use SelectableItem::*;
        match self {
            Selectable(_, s) => *s = SelectedState::Selected,
            _ => {}
        }
    }

    pub fn unselect(&mut self) {
        use SelectableItem::*;
        match self {
            Selectable(_, s) => *s = SelectedState::Unselected,
            _ => {}
        }
    }

    pub fn inner(&self) -> &T {
        match &self {
            SelectableItem::Selectable(inner, _) => inner,
            SelectableItem::Disabled(inner) => inner,
            SelectableItem::Subheading(inner) => inner,
        }
    }

    fn inner_mut(&mut self) -> &mut T {
        match self {
            SelectableItem::Selectable(inner, _) => inner,
            SelectableItem::Disabled(inner) => inner,
            SelectableItem::Subheading(inner) => inner,
        }
    }
}

impl<T: PartialEq> PartialEq for SelectableItem<T> {
    fn eq(&self, other: &Self) -> bool {
        self.inner() == other.inner()
    }
}

impl<T: PartialOrd> PartialOrd for SelectableItem<T> {
    fn partial_cmp(&self, other: &Self) -> Option<Ordering> {
        self.inner().partial_cmp(other.inner())
    }
}

impl<T: Ord + PartialOrd> Ord for SelectableItem<T> {
    fn cmp(&self, other: &Self) -> Ordering {
        self.inner().cmp(other.inner())
    }
}

#[derive(Debug, Clone, Data, Eq, PartialEq, Ord, PartialOrd)]
pub enum SelectedState {
    Selected,
    Unselected,
    // Hovered(SelectedState),
}
