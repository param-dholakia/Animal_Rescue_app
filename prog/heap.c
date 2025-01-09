  #include<stdio.h>
  #include<stdlib.h>
  int heapsize = 0;
  int n=100;
  void swap(int *A,int *B)
  {
    int temp;
    temp=*A;
    *A=*B;
    *B=temp;
  }
  void heapify(int *a,int i)
  {
    int left=2*i;
    int right=2*i+1;
    int largest=i;

    if(left<=heapsize && a[left]>a[largest])
        largest=left;
    if(right<=heapsize && a[right]>a[largest])
        largest=right;

    if(largest!=i)
    {
        swap(&a[i],&a[largest]);
        heapify(a,largest);
    }
  }
  void buildheap(int *a)
  {
    int i;
    for(i=n/2;i>=1;i--)
        heapify(a,i);
  }
  void heap_sort(int *a)
  {
    buildheap(a);
    int i;
    for(i=n;i>=2;i--)
    {
        swap(&a[1],&a[i]);
        heapsize--;
        heapify(a,1);
    }
  }

  void main()
  {
    printf("Enter the number of elements: ");
    scanf("%d",&heapsize);
    n=heapsize;
    int a[n+1],i;
    for(i=1;i<=n;i++)
        a[i]=rand();

    printf("Original array is: ");
    for(i=1;i<=n;i++)    
    {
        printf("%d ",a[i]);
    }    
    heap_sort(a);
    printf("\nSorted array is: ");
    for(i=1;i<=n;i++)    
    {
        printf("%d ",a[i]);
    }
  }
